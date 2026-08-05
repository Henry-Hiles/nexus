import "dart:convert";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/account_data.dart";

class AccountDataController extends Notifier<AccountData> {
  @override
  AccountData build() => .new();

  void update(IMap<String, IMap<String, dynamic>> newAccountData) =>
      state = .fromJson({
        ...json.decode(json.encode(state.toJson())),
        ...newAccountData
            .map((key, value) => MapEntry(key, value["content"]))
            .unlock,
      });

  static final provider = NotifierProvider<AccountDataController, AccountData>(
    AccountDataController.new,
  );
}
