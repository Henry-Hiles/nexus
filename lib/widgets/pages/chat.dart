import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/init_complete.dart";
import "package:nexus/controllers/jump_to_event.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/sidebar.dart";
import "package:nexus/widgets/room_chat/room_chat.dart";
import "package:nexus/widgets/loading.dart";

class const ChatPage({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 650;
      final showMembersByDefault = constraints.maxWidth > 1000;
      final initComplete = ref.watch(InitCompleteController.provider);
      final roomId = ref
          .watch(KeyController.provider(KeyController.roomKey))
          .requireValue;

      return SafeArea(
        child: Scaffold(
          appBar: initComplete ? null : Appbar(),
          body: initComplete
              ? Row(
                  children: [
                    if (isDesktop) Sidebar(isDesktop: isDesktop),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final initialHighlight = ref.watch(
                            JumpToEventController.provider,
                          );
                          return RoomChat(
                            key: ValueKey((roomId, initialHighlight)),
                            roomId: roomId,
                            isDesktop: isDesktop,
                            initialHighlightedEvent: initialHighlight,
                            showMembersByDefault: showMembersByDefault,
                          );
                        },
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
        ),
      );
    },
  );
}
