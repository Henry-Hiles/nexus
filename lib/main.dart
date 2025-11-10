import "dart:io";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/widgets/room_chat.dart";
import "package:nexus/widgets/sidebar.dart";
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
                  Expanded(
                    child: Scaffold(
                      appBar: AppBar(
                        leading: isDesktop
                            ? null
                            : DrawerButton(
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                              ),
                        actionsPadding: EdgeInsets.symmetric(horizontal: 8),
                        title: Text("Some Chat Name"),
                        actions: [
                          if (!(Platform.isAndroid || Platform.isIOS))
                            IconButton(
                              onPressed: () => exit(0),
                              icon: Icon(Icons.close),
                            ),
                        ],
                      ),
                      body: RoomChat(),
                    ),
                  ),
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
