import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/scheme_to_theme.dart";
import "package:nexus/pages/chat_page.dart";
import "package:nexus/pages/login_page.dart";
import "package:window_manager/window_manager.dart";
import "package:flutter/material.dart";
import "package:dynamic_system_colors/dynamic_system_colors.dart";
import "package:window_size/window_size.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      // Use indigo to work around bugs in theme generation
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
                client.accessToken == null ? LoginPage() : ChatPage(),
          ),
    ),
  );
}
