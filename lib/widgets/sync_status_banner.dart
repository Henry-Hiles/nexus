import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/sync_status.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:timeago/timeago.dart";

class const SyncStatusBanner({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(SyncStatusController.provider);
    final colorScheme = Theme.of(context).colorScheme;

    final banner = switch (status?.type) {
      null || .ok => null,
      .waiting => (
        title: "Waiting for sync...",
        icon: Icons.sync,
        background: colorScheme.primary,
        foreground: colorScheme.onPrimary,
      ),
      .erroring => (
        title: "Sync is failing, retrying...",
        icon: Icons.sync_problem,
        background: colorScheme.error,
        foreground: colorScheme.onError,
      ),
      .permanentlyFailed => (
        title: "Sync has permanently failed",
        icon: Icons.cloud_off,
        background: colorScheme.error,
        foreground: colorScheme.onError,
      ),
    };

    final details = status == null
        ? []
        : [
            ?status.error,
            if (status.errorCount > 0) "Failed attempts: ${status.errorCount}.",
            if (status.lastSync case final lastSync?)
              "Last synced ${format(lastSync)}.",
          ];

    return AnimatedSize(
      duration: Durations.short4,
      alignment: .topCenter,
      child: banner == null
          ? const SizedBox(width: double.infinity)
          : Material(
              color: banner.background,
              child: InkWell(
                onTap: details.isEmpty
                    ? null
                    : () => showDialog(
                        context: context,
                        builder: (context) =>
                            ErrorDialog(details.join("\n\n"), null),
                      ),
                child: Padding(
                  padding: const .symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    spacing: 12,
                    children: [
                      Icon(banner.icon, size: 20, color: banner.foreground),
                      Expanded(
                        child: Text(
                          banner.title,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: TextStyle(
                            color: banner.foreground,
                            fontWeight: .bold,
                          ),
                        ),
                      ),
                      if (details.isNotEmpty)
                        Icon(Icons.info_outline, color: banner.foreground),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
