import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";

/// A room's aliases on the user's own server.
class LocalAliasesController(final String roomId)
    extends AsyncNotifier<IList<String>> {
  @override
  Future<IList<String>> build() =>
      ref.read(ClientController.provider.notifier).getLocalAliases(roomId);

  Future<void> add(String alias) async {
    await ref
        .read(ClientController.provider.notifier)
        .createAlias(roomId, alias);
    ref.invalidateSelf();
  }

  Future<void> remove(String alias) async {
    await ref.read(ClientController.provider.notifier).deleteAlias(alias);
    ref.invalidateSelf();
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<LocalAliasesController, IList<String>, String>(
        LocalAliasesController.new,
      );
}
