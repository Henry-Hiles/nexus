import "dart:async";
import "dart:convert";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/account_data.dart";

class AccountDataController extends Notifier<AccountData> {
  @override
  AccountData build() => .new();

  void update(IMap<String, IMap<String, dynamic>> newAccountData) =>
      state = newAccountData.entries.fold(state, (data, entry) {
        try {
          return .fromJson({
            ...json.decode(json.encode(data.toJson())),
            entry.key: entry.value["content"],
          });
        } catch (error) {
          debugPrint("Ignoring invalid ${entry.key} account data: $error");
          return data;
        }
      });

  Future<void> setEnabledImagePacks(ImagePackRooms packs) async {
    ISet<(String, String)> keysOf(ImagePackRooms rooms) => rooms.rooms.entries
        .expand((entry) => entry.value.keys.map((key) => (entry.key, key)))
        .toISet();
    final keys = keysOf(packs);
    bool arrived(AccountData data) {
      final current = keysOf(data.enabledImagePacks);
      return current.length == keys.length && current.containsAll(keys);
    }

    final completer = Completer<void>();
    final removeListener = listenSelf((_, data) {
      if (arrived(data) && !completer.isCompleted) completer.complete();
    });

    try {
      final client = ref.read(ClientController.provider.notifier);
      await Future.wait([
        if (state.imagePackRooms != null)
          client.setAccountData(
            .new(type: AccountData.imagePackRoomsKey, content: packs),
          ),
        client.setAccountData(
          .new(type: AccountData.legacyImagePackRoomsKey, content: packs),
        ),
      ]);

      if (!arrived(state)) {
        await completer.future.timeout(
          const .new(seconds: 10),
          onTimeout: () {},
        );
      }
    } finally {
      removeListener();
    }
  }

  static final provider = NotifierProvider<AccountDataController, AccountData>(
    AccountDataController.new,
  );
}
