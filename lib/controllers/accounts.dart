import "dart:convert";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/models/account.dart";

class AccountsController extends AsyncNotifier<IList<Account>> {
  @override
  Future<IList<Account>> build() async {
    final stored = await ref.watch(
      KeyController.provider(KeyController.accountsKey).future,
    );
    final accounts = IList<Account>(
      (json.decode(stored ?? "[]") as List).map(
        (account) => .fromJson(account),
      ),
    );

    // Installs from before account switching are logged into the legacy slot
    return accounts.isEmpty
        ? .new([const .new(id: Account.legacyId)])
        : accounts;
  }

  Future<void> _set(IList<Account> accounts) async {
    state = .data(accounts);
    await ref
        .read(KeyController.provider(KeyController.accountsKey).notifier)
        .set(json.encode(accounts.map((account) => account.toJson()).toList()));
  }

  Future<IList<Account>> get _current async {
    await future;
    return state.requireValue;
  }

  Future<void> save(Account account) async {
    final accounts = await _current;
    final index = accounts.indexWhere((existing) => existing.id == account.id);

    await _set(
      index == -1 ? accounts.add(account) : accounts.replace(index, account),
    );
  }

  Future<void> reset(String id) async {
    final accounts = await _current;
    final index = accounts.indexWhere((account) => account.id == id);
    if (index != -1) await _set(accounts.replace(index, .new(id: id)));
  }

  Future<void> remove(String id) async =>
      _set((await _current).removeWhere((account) => account.id == id));

  static final provider =
      AsyncNotifierProvider<AccountsController, IList<Account>>(
        AccountsController.new,
      );
}
