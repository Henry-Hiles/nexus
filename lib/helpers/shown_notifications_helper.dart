import "dart:convert";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/shared_prefs.dart";

class ShownNotificationsHelper(final Ref ref) {
  static const _key = "shownNotifications";

  /// Applies [update], returning the IDs from before it.
  Future<IMap<String, ISet<int>>> _update(
    IMap<String, ISet<int>> Function(IMap<String, ISet<int>> shown) update,
  ) async {
    final prefs = ref.read(SharedPrefsController.provider);
    final shown = IMap<String, ISet<int>>.fromJson(
      json.decode(await prefs.getString(_key) ?? "{}"),
      (threadId) => threadId as String,
      (ids) => ISet.fromJson(ids, (id) => id as int),
    );

    await prefs.setString(
      _key,
      json.encode(
        update(shown)
            .toJson((threadId) => threadId, (ids) => ids.toJson((id) => id)),
      ),
    );
    return shown;
  }

  Future<void> add(String threadId, int id) => _update(
    (shown) => shown.update(
      threadId,
      (ids) => ids.add(id),
      ifAbsent: () => ISet({id}),
    ),
  );

  /// Forgets the notifications shown for [threadIds], returning their IDs.
  Future<Iterable<int>> remove(ISet<String> threadIds) async {
    final shown = await _update(
      (shown) =>
          shown.removeWhere((threadId, _) => threadIds.contains(threadId)),
    );
    return threadIds.map((threadId) => shown[threadId]).nonNulls.flattened;
  }

  static final provider = Provider<ShownNotificationsHelper>(
    ShownNotificationsHelper.new,
  );
}
