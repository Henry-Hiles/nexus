import "dart:async";
import "dart:convert";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/account_data.dart";
import "package:nexus/models/push_rules.dart";
import "package:nexus/models/requests/update_push_rule.dart";

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

  Future<void> setEnabledImagePacks(ImagePackRooms packs) {
    ISet<(String, String)> keysOf(ImagePackRooms rooms) => rooms.rooms.entries
        .expand((entry) => entry.value.keys.map((key) => (entry.key, key)))
        .toISet();
    final keys = keysOf(packs);
    final client = ref.read(ClientController.provider.notifier);

    return _sendAndWait(
      () => .wait([
        if (state.imagePackRooms != null)
          client.setAccountData(
            .new(type: AccountData.imagePackRoomsKey, content: packs),
          ),
        client.setAccountData(
          .new(type: AccountData.legacyImagePackRoomsKey, content: packs),
        ),
      ]),
      (data) {
        final current = keysOf(data.enabledImagePacks);
        return current.length == keys.length && current.containsAll(keys);
      },
    );
  }

  /// Saves [rule] of [kind], creating it if it's new, or otherwise changing only
  /// its actions and whether it's enabled.
  Future<void> savePushRule(PushRuleKind kind, PushRule rule) {
    UpdatePushRuleRequest request(UpdatePushRuleAction action) =>
        .new(kind: kind, ruleId: rule.ruleId, action: action);

    return _updatePushRules(
      .new(switch (state.pushRules.global.find(kind, rule.ruleId)) {
        null => [request(.put).copyWith(newContent: rule)],
        final previous => [
          if (previous.actions != rule.actions)
            request(.putActions).copyWith(actions: rule.actions),
          if (previous.enabled != rule.enabled)
            request(rule.enabled ? .enable : .disable),
        ],
      }),
      (rules) => rules.find(kind, rule.ruleId) == rule,
    );
  }

  Future<void> deletePushRule(PushRuleKind kind, String ruleId) =>
      _updatePushRules(
        .new([.new(kind: kind, ruleId: ruleId, action: .delete)]),
        (rules) => rules.find(kind, ruleId) == null,
      );

  /// Sends [requests] in order, then waits until [arrived] is true for the
  /// synced push rules.
  Future<void> _updatePushRules(
    IList<UpdatePushRuleRequest> requests,
    bool Function(PushRuleset rules) arrived,
  ) => _sendAndWait(
    () => .forEach(
      requests,
      ref.read(ClientController.provider.notifier).updatePushRule,
    ),
    (data) => arrived(data.pushRules.global),
  );

  /// Runs [send], then waits until [arrived] is true for the synced data.
  Future<void> _sendAndWait(
    Future<void> Function() send,
    bool Function(AccountData data) arrived,
  ) async {
    final completer = Completer<void>();
    final removeListener = listenSelf((_, data) {
      if (arrived(data) && !completer.isCompleted) completer.complete();
    });

    try {
      await send();
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
