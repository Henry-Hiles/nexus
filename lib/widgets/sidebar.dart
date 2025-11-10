import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

class Sidebar extends HookWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final index = useState(0);
    return Drawer(
      shape: Border(),
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
                padding: EdgeInsets.only(top: 12),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text("Messages"),
                padding: EdgeInsets.only(top: 12),
              ),
              NavigationRailDestination(
                icon: Image.file(File("assets/icon.png"), width: 40),
                label: Text("Space 1"),
                padding: EdgeInsets.only(top: 12),
              ),
            ],
            selectedIndex: index.value,
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text("Some Space"),
                backgroundColor: Colors.transparent,
              ),
              body: NavigationRail(
                backgroundColor: Colors.transparent,
                extended: true,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.numbers),
                    label: Text("Room 1"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.numbers),
                    label: Text("Room 2"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.numbers),
                    label: Text("Room 3"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.numbers),
                    label: Text("Room 4"),
                  ),
                ],
                selectedIndex: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
