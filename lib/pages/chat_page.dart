import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/init_complete_controller.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/sidebar.dart";
import "package:nexus/widgets/room_chat.dart";
import "package:nexus/widgets/loading.dart";

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 650;
      final showMembersByDefault = constraints.maxWidth > 1000;
      final initComplete = ref.watch(InitCompleteController.provider);
      final roomId = ref.watch(KeyController.provider(KeyController.roomKey));

      return Scaffold(
        appBar: initComplete ? null : Appbar(),
        body: initComplete
            ? Row(
                children: [
                  if (isDesktop) Sidebar(isDesktop: isDesktop),
                  Expanded(
                    child: RoomChat(
                      roomId: roomId,
                      isDesktop: isDesktop,
                      showMembersByDefault: showMembersByDefault,
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisSize: .min,
                  children: [Loading(), Text("Syncing...")],
                ),
              ),
        drawer: isDesktop || !initComplete
            ? null
            : Sidebar(isDesktop: isDesktop),
      );
    },
  );
}
