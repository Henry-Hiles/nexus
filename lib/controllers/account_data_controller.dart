import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/account_data.dart";

class AccountDataController extends Notifier<IMap<String, AccountData>> {
  @override
  IMap<String, AccountData> build() => const IMap.empty();

  void update(IMap<String, AccountData> newData) =>
      state = IMap({...state.unlock, ...newData.unlock});

  static final provider =
      NotifierProvider<AccountDataController, IMap<String, AccountData>>(
        AccountDataController.new,
      );
}
