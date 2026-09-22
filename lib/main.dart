import "dart:io";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:media_kit/media_kit.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/member_list_opened.dart";
import "package:nexus/controllers/multi_provider.dart";
import "package:nexus/controllers/notification.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/controllers/unified_push.dart";
import "package:nexus/helpers/extensions/scheme_to_theme.dart";
import "package:nexus/helpers/font_licenses.dart";
import "package:nexus/pages/chat.dart";
import "package:nexus/pages/select_server.dart";
import "package:nexus/pages/settings.dart";
import "package:nexus/pages/verify.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";
import "package:window_manager/window_manager.dart";
import "package:material_ui/material_ui.dart";

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late final bool isInBackground;

final class Logger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) => debugPrint("""
Time: ${DateTime.now().toIso8601String()}
Provider: ${context.provider}
Previous Value: ${previousValue is AsyncData ? previousValue.value : previousValue}
New Value: ${newValue is AsyncData ? newValue.value : newValue}
""");
}

void showError(Object error, [StackTrace? stackTrace]) {
  if (error.toString().contains("DioException") ||
      error.toString().contains(
        "setState() or markNeedsBuild() called during build.",
      ) ||
      error.toString().contains("Invalid source") ||
      error.toString().contains("UTF-16") ||
      error.toString().contains("HTTP request failed") ||
      error.toString().contains("'_nextFrame != null': is not true.") ||
      error.toString().contains("Invalid image data")) {
    return;
  }

  debugPrintStack(stackTrace: stackTrace, label: error.toString());
  if (navigatorKey.currentContext != null) {
    Future.delayed(
      Duration.zero,
      () => showDialog(
        context: navigatorKey.currentContext!,
        builder: (_) => ErrorDialog(error, stackTrace),
        barrierDismissible: false,
      ),
    );
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
      ),
    );
    await windowManager.setMinimumSize(Size.square(500));
  }

  isInBackground =
      Platform.environment["FLUTTER_HEADLESS"] != null ||
      args.contains("--unifiedpush-bg");

  LicenseRegistry.addLicense(() => .fromIterable(fontLicenses));

  FlutterError.onError = (FlutterErrorDetails details) =>
      showError(details.exception.toString(), details.stack);

  if (isInBackground) {
    await ProviderContainer().read(UnifiedPushController.provider.future);

    // In case it didn't exit for some reason
    await Future.delayed(Duration(seconds: 20));
    exit(0);
  } else {
    runApp(
      ProviderScope(
        retry: (_, _) => null,
        observers: [
          // Change false to true if you want debug information on provider reloads
          // ignore: dead_code
          if (false && kDebugMode) Logger(),
        ],
        child: App(),
      ),
    );
  }
}

class const App({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DynamicColorBuilder(
    builder: (lightDynamic, darkDynamic) => Consumer(
      builder: (context, ref, child) => MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme:
            (ref
                        .watch(SettingsController.provider)
                        .maybeWhen(
                          orElse: () => lightDynamic,
                          data: (settings) =>
                              settings.useDynamicTheming ? lightDynamic : null,
                        ) ??
                    ThemeData.light().colorScheme)
                .theme,
        darkTheme:
            (ref
                        .watch(SettingsController.provider)
                        .maybeWhen(
                          orElse: () => darkDynamic,
                          data: (settings) =>
                              settings.useDynamicTheming ? darkDynamic : null,
                        ) ??
                    ThemeData.dark().colorScheme)
                .theme,
        themeMode: ref
            .watch(SettingsController.provider)
            .maybeWhen(
              data: (settings) => settings.theme,
              orElse: () => ThemeMode.system,
            ),
        home: child,
      ),
      child: Scaffold(
        body: Consumer(
          builder: (_, ref, _) => switch (ref.watch(
            MultiProviderController.provider(
              .new([
                ClientController.provider,
                NotificationController.provider,
                UnifiedPushController.provider,
                MemberListOpenedController.provider,
                KeyController.provider(KeyController.roomKey),
                KeyController.provider(KeyController.spaceKey),
              ]),
            ),
          )) {
            AsyncData(value: _) || AsyncLoading(value: _?) => Consumer(
              builder: (_, ref, _) {
                final clientState = ref.watch(ClientStateController.provider);

                if (clientState == null || !clientState.isInitialized) {
                  return Loading();
                }

                if (!clientState.isLoggedIn) {
                  return SelectServerPage();
                } else if (!clientState.isVerified) {
                  return VerifyPage();
                } else {
                  return ChatPage();
                }
              },
            ),

            AsyncLoading _ => Scaffold(
              appBar: Appbar(
                actions: .new([
                  IconButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => SettingsPage(),
                    ),
                    icon: Icon(Icons.settings),
                  ),
                ]),
              ),
              body: Loading(),
            ),
            AsyncError(:final error, :final stackTrace) => ErrorDialog(
              error,
              stackTrace,
            ),
          },
        ),
      ),
    ),
  );
}
