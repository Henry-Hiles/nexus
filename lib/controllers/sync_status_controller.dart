import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/main.dart";
import "package:nexus/models/sync_status.dart";

class SyncStatusController extends Notifier<SyncStatus?> {
  @override
  Null build() => null;

  void set(SyncStatus newStatus) {
    if (newStatus.type == SyncStatusType.permanentlyFailed) {
      showError(newStatus.error ?? "Syncing failed");
    }
    state = newStatus;
  }

  static final provider = NotifierProvider<SyncStatusController, SyncStatus?>(
    SyncStatusController.new,
  );
}
