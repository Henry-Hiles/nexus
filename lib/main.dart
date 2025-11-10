import "dart:io";
import "package:window_manager/window_manager.dart";
import "package:flutter/material.dart";
import "package:dynamic_system_colors/dynamic_system_colors.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:window_size/window_size.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  await windowManager.waitUntilReadyToShow(
    WindowOptions(titleBarStyle: TitleBarStyle.hidden),
  );

  setWindowMinSize(const Size.square(500));

  runApp(const App());
}

class App extends HookWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final index = useState(0);
    final drawer = Drawer(
      child: Row(
        children: [
          NavigationRail(
            useIndicator: false,
            labelType: NavigationRailLabelType.none,
            onDestinationSelected: (value) => index.value = value,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text("Home"),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              NavigationRailDestination(
                icon: Image.file(File("assets/icon.png"), width: 35),
                label: Text("Space 1"),
              ),
            ],
            selectedIndex: index.value,
          ),
        ],
      ),
    );

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 650;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.from(
              colorScheme: lightDynamic ?? ColorScheme.light(),
            ),
            darkTheme: ThemeData.from(
              colorScheme: darkDynamic ?? ColorScheme.dark(),
            ),
            home: Scaffold(
              appBar: isDesktop ? null : AppBar(),
              body: Row(
                children: [
                  if (isDesktop) drawer,
                  Expanded(child: Column()),
                ],
              ),
              drawer: isDesktop ? null : drawer,
            ),
          );
        },
      ),
    );
  }
}
