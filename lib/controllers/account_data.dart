import "dart:convert";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
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

  static final provider = NotifierProvider<AccountDataController, AccountData>(
    AccountDataController.new,
  );
}
