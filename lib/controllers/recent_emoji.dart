import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_emoji_picker/material_emoji_picker.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/account_data.dart";

class RecentEmojiController extends Notifier<IList<RecentEmoji>> {
  @override
  IList<RecentEmoji> build() {
    final Set<String> emoji = ref
        .watch(EmojiController.provider)
        .requireValue
        .map((element) => element.emojis)
        .flattened
        .map((e) => e.value)
        .toSet();

    final IList<RecentEmoji> recents = ref.watch(
      AccountDataController.provider.select(
        (value) => value.recentEmoji.recentEmoji,
      ),
    );

    return .new(recents.where((recent) => emoji.contains(recent.emoji)));
  }

  Future<void> add(String emoji) => ref
      .watch(ClientController.provider.notifier)
      .setAccountData(
        .new(
          type: AccountData.recentEmojiKey,
          content: RecentEmojiData(
            recentEmoji: .new([
              .new(
                emoji: emoji,
                total:
                    (state
                            .firstWhereOrNull(
                              (element) => element.emoji == emoji,
                            )
                            ?.total ??
                        0) +
                    1,
              ),
              ...state.whereNot((element) => element.emoji == emoji),
            ]),
          ),
        ),
      );

  static final provider =
      NotifierProvider.autoDispose<RecentEmojiController, IList<RecentEmoji>>(
        RecentEmojiController.new,
      );
}
