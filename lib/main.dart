import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/pages/home_page.dart";
import "package:nexus/pages/homeserver_page.dart";
import "package:scaled_app/scaled_app.dart";
import "package:window_manager/window_manager.dart";
import "package:flutter/material.dart";
import "package:dynamic_system_colors/dynamic_system_colors.dart";
import "package:window_size/window_size.dart";

void main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized(scaleFactor: (size) => 1);

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    WindowOptions(titleBarStyle: TitleBarStyle.hidden),
  );

  setWindowMinSize(const Size.square(500));

  runApp(ProviderScope(child: const App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DynamicColorBuilder(
    builder: (lightDynamic, darkDynamic) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: (lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.indigo))
          .theme,
      darkTheme:
          (darkDynamic ??
                  ColorScheme.fromSeed(
                    seedColor: Colors.indigo,
                    brightness: Brightness.dark,
                  ))
              .theme,
      home: ref
          .watch(ClientController.provider)
          .betterWhen(
            data: (client) =>
                client.accessToken == null ? HomeserverPage() : HomePage(),
          ),
    ),
  );
}
