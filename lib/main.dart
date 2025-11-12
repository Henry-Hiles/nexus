import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/widgets/room_chat.dart";
import "package:nexus/widgets/sidebar.dart";
import "package:scaled_app/scaled_app.dart";
import "package:window_manager/window_manager.dart";
import "package:flutter/material.dart";
import "package:dynamic_system_colors/dynamic_system_colors.dart";
import "package:window_size/window_size.dart";

void main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized(scaleFactor: (_) => 1.4);

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    WindowOptions(titleBarStyle: TitleBarStyle.hidden),
  );

  setWindowMinSize(const Size.square(500));

  runApp(ProviderScope(child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => DynamicColorBuilder(
    builder: (lightDynamic, darkDynamic) => LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 650;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.from(
            colorScheme:
                lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          darkTheme: ThemeData.from(
            colorScheme:
                darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: Colors.indigo,
                  brightness: Brightness.dark,
                ),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Row(
                children: [
                  if (isDesktop) Sidebar(),
                  Expanded(child: RoomChat(isDesktop: isDesktop)),
                ],
              ),
            ),
            drawer: isDesktop ? null : Sidebar(),
          ),
        );
      },
    ),
  );
}
