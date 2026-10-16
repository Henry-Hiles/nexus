import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/init_complete.dart";
import "package:nexus/controllers/selected_room.dart";
import "package:nexus/controllers/notification_request.dart";
import "package:nexus/helpers/extensions/is_desktop.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/sidebar.dart";
import "package:nexus/widgets/sync_status_banner.dart";
import "package:nexus/widgets/room_chat/room_chat.dart";
import "package:nexus/widgets/loading.dart";

class const ChatPage({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = useMemoized(GlobalKey<ScaffoldState>.new);
    final initComplete = ref.watch(InitCompleteController.provider);
    final notificationRequest = ref.watch(
      NotificationRequestController.provider,
    );

    // On mobile, open the drawer so the sidebar can show the tapped notification
    useEffect(() {
      if (notificationRequest == null || !initComplete) return null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scaffold = scaffoldKey.currentState;
        if (scaffold != null && scaffold.hasDrawer && !scaffold.isDrawerOpen) {
          scaffold.openDrawer();
        }
      });
      return null;
    }, [notificationRequest, initComplete]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = context.isDesktop;
        final showMembersByDefault = constraints.maxWidth > 1000;
        final roomId = ref.watch(SelectedRoomController.provider);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) scaffoldKey.currentState?.openDrawer();
          },
          child: SafeArea(
            child: Scaffold(
              key: scaffoldKey,
              appBar: initComplete ? null : Appbar(),
              body: initComplete
                  ? Row(
                      children: [
                        if (isDesktop) Sidebar(),
                        Expanded(
                          child: RoomChat(
                            key: ValueKey(roomId),
                            roomId: roomId,
                            isDesktop: isDesktop,
                            showMembersByDefault: showMembersByDefault,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const SyncStatusBanner(),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: .min,
                              children: [Loading(), Text("Syncing...")],
                            ),
                          ),
                        ),
                      ],
                    ),
              drawer: isDesktop || !initComplete ? null : Sidebar(),
            ),
          ),
        );
      },
    );
  }
}
