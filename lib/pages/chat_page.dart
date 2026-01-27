import "package:flutter/material.dart";
import "package:nexus/widgets/chat_page/sidebar.dart";
import "package:nexus/widgets/chat_page/room_chat.dart";

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 650;
      final showMembersByDefault = constraints.maxWidth > 1000;

      return Scaffold(
        body: Builder(
          builder: (context) => Row(
            children: [
              if (isDesktop) Sidebar(),
              Expanded(
                child: RoomChat(
                  isDesktop: isDesktop,
                  showMembersByDefault: showMembersByDefault,
                ),
              ),
            ],
          ),
        ),
        drawer: isDesktop ? null : Sidebar(),
      );
    },
  );
}
