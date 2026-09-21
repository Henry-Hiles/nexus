#include "my_application.h"

#include <cstdlib>

#include <flutter_linux/flutter_linux.h>
#include <flutter_linux/fl_method_channel.h>
#include <flutter_linux/fl_standard_method_codec.h>

#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;

  char** dart_entrypoint_arguments;

  FlEngine* flutter_engine;
  FlMethodChannel* notification_channel;

  gchar* pending_notification_event_id;
  gboolean flutter_ready;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void my_application_activate(GApplication* application);

static void send_notification_event_to_flutter(
    MyApplication* self,
    const gchar* event_id) {
  if (self->notification_channel == nullptr ||
      !self->flutter_ready) {
    g_free(self->pending_notification_event_id);
    self->pending_notification_event_id = g_strdup(event_id);
    return;
  }

  g_autoptr(FlValue) args =
      fl_value_new_string(event_id);

  fl_method_channel_invoke_method(
      self->notification_channel,
      "notificationClicked",
      args,
      nullptr,
      nullptr,
      nullptr);
}

static void notification_event_action(
    GSimpleAction* action,
    GVariant* parameter,
    gpointer user_data) {
  MyApplication* self =
      MY_APPLICATION(user_data);

  if (parameter == nullptr) {
    g_warning(
        "Notification event action invoked without a target");
    return;
  }

  if (!g_variant_is_of_type(
          parameter,
          G_VARIANT_TYPE_STRING)) {
    g_warning(
        "Notification event action received unexpected parameter type: %s",
        g_variant_get_type_string(parameter));
    return;
  }

  const gchar* event_id =
      g_variant_get_string(parameter, nullptr);

  g_message(
      "Notification event activated: %s",
      event_id);

  send_notification_event_to_flutter(
      self,
      event_id);

  GList* windows =
      gtk_application_get_windows(
          GTK_APPLICATION(self));

  if (windows != nullptr) {
    gtk_window_present(
        GTK_WINDOW(windows->data));
  } else {
    my_application_activate(
        G_APPLICATION(self));
  }
}

static void first_frame_cb(
    MyApplication* self,
    FlView* view) {
  self->flutter_ready = TRUE;

  gtk_widget_show(
      gtk_widget_get_toplevel(
          GTK_WIDGET(view)));

  if (self->pending_notification_event_id != nullptr) {
    gchar* event_id =
        self->pending_notification_event_id;

    self->pending_notification_event_id = nullptr;

    send_notification_event_to_flutter(
        self,
        event_id);

    g_free(event_id);
  }
}

static void my_application_activate(
    GApplication* application) {
  MyApplication* self =
      MY_APPLICATION(application);

  GList* windows =
      gtk_application_get_windows(
          GTK_APPLICATION(application));

  if (windows != nullptr) {
    gtk_window_present(
        GTK_WINDOW(windows->data));
    return;
  }

  GtkWindow* window =
      GTK_WINDOW(
          gtk_application_window_new(
              GTK_APPLICATION(application)));

  gboolean use_header_bar = TRUE;

#ifdef GDK_WINDOWING_X11
  GdkScreen* screen =
      gtk_window_get_screen(window);

  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name =
        gdk_x11_screen_get_window_manager_name(screen);

    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif

  gtk_widget_set_size_request(
      GTK_WIDGET(window),
      250,
      -1);

  if (use_header_bar) {
    GtkHeaderBar* header_bar =
        GTK_HEADER_BAR(
            gtk_header_bar_new());

    gtk_widget_show(
        GTK_WIDGET(header_bar));

    gtk_header_bar_set_title(
        header_bar,
        "nexus");

    gtk_header_bar_set_show_close_button(
        header_bar,
        TRUE);

    gtk_window_set_titlebar(
        window,
        GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(
        window,
        "nexus");
  }

  gtk_window_set_default_size(
      window,
      1280,
      720);

  g_autoptr(FlDartProject) project =
      fl_dart_project_new();

  fl_dart_project_set_dart_entrypoint_arguments(
      project,
      self->dart_entrypoint_arguments);

  FlView* view =
      fl_view_new(project);

  self->flutter_engine =
      fl_view_get_engine(view);

  g_autoptr(FlStandardMethodCodec) codec =
      fl_standard_method_codec_new();

  self->notification_channel =
      fl_method_channel_new(
          fl_engine_get_binary_messenger(
              self->flutter_engine),
          "nexus/notifications",
          FL_METHOD_CODEC(codec));

  GdkRGBA background_color;

  gdk_rgba_parse(
      &background_color,
      "#000000");

  fl_view_set_background_color(
      view,
      &background_color);

  gtk_widget_show(
      GTK_WIDGET(view));

  if (std::getenv("FLUTTER_HEADLESS")) {
    gtk_widget_hide(
        GTK_WIDGET(window));
  }

  gtk_container_add(
      GTK_CONTAINER(window),
      GTK_WIDGET(view));

  g_signal_connect_swapped(
      view,
      "first-frame",
      G_CALLBACK(first_frame_cb),
      self);

  gtk_widget_realize(
      GTK_WIDGET(view));

  fl_register_plugins(
      FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(
      GTK_WIDGET(view));
}

static gboolean my_application_local_command_line(
    GApplication* application,
    gchar*** arguments,
    int* exit_status) {
  MyApplication* self =
      MY_APPLICATION(application);

  self->dart_entrypoint_arguments =
      g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;

  if (!g_application_register(
          application,
          nullptr,
          &error)) {
    g_warning(
        "Failed to register: %s",
        error->message);

    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);

  *exit_status = 0;

  return TRUE;
}

static void my_application_startup(
    GApplication* application) {
  g_message(
      "GApplication application-id: %s",
      g_application_get_application_id(
          application));

  g_message(
      "GApplication is remote: %d",
      g_application_get_is_remote(
          application));

  g_message(
      "GApplication is registered: %d",
      g_application_get_is_registered(
          application));

  g_message(
      "prgname: %s",
      g_get_prgname());

  G_APPLICATION_CLASS(
      my_application_parent_class)
      ->startup(application);
}

static void my_application_shutdown(
    GApplication* application) {
  G_APPLICATION_CLASS(
      my_application_parent_class)
      ->shutdown(application);
}

static void my_application_dispose(
    GObject* object) {
  MyApplication* self =
      MY_APPLICATION(object);

  g_clear_pointer(
      &self->dart_entrypoint_arguments,
      g_strfreev);

  g_clear_pointer(
      &self->pending_notification_event_id,
      g_free);

  g_clear_object(
      &self->notification_channel);

  self->flutter_engine = nullptr;

  G_OBJECT_CLASS(
      my_application_parent_class)
      ->dispose(object);
}

static void my_application_class_init(
    MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate =
      my_application_activate;

  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;

  G_APPLICATION_CLASS(klass)->startup =
      my_application_startup;

  G_APPLICATION_CLASS(klass)->shutdown =
      my_application_shutdown;

  G_OBJECT_CLASS(klass)->dispose =
      my_application_dispose;
}

static void my_application_init(
    MyApplication* self) {
  self->dart_entrypoint_arguments = nullptr;
  self->flutter_engine = nullptr;
  self->notification_channel = nullptr;
  self->pending_notification_event_id = nullptr;
  self->flutter_ready = FALSE;

  GSimpleAction* action =
      g_simple_action_new(
          "event",
          G_VARIANT_TYPE_STRING);

  g_signal_connect(
      action,
      "activate",
      G_CALLBACK(notification_event_action),
      self);

  g_action_map_add_action(
      G_ACTION_MAP(self),
      G_ACTION(action));

  g_object_unref(action);
}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(
      g_object_new(
          my_application_get_type(),
          "application-id",
          APPLICATION_ID,
          "flags",
          G_APPLICATION_HANDLES_COMMAND_LINE |
              G_APPLICATION_HANDLES_OPEN,
          nullptr));
}