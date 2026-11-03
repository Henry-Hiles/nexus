import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/sync_data.dart";

class TopLevelSpacesController extends Notifier<IList<String>> {
  @override
  IList<String> build() => .new();

  void handleSync(SyncData sync) => state = sync.topLevelSpaces ?? state;

  static final provider =
      NotifierProvider<TopLevelSpacesController, IList<String>>(
        TopLevelSpacesController.new,
      );
}
