import "dart:convert";
import "package:emoji_text_field/models/emoji_category.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart";
import "package:nexus/models/emoji.dart";

typedef EmojiTuple = (IMap<String, EmojiCategory>, IMap<String, List<String>>);

class EmojiController extends AsyncNotifier<EmojiTuple> {
  @override
  Future<EmojiTuple> build() async {
    final response = await get(
      Uri.https(
        "github.com",
        "github/gemoji/raw/refs/heads/master/db/emoji.json",
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load emoji data");
    }

    final data = json.decode(response.body);

    final entries = (data as List)
        .cast<Map<String, dynamic>>()
        .map(Emoji.fromJson)
        .toIList();

    final categoryMap = entries.fold<IMap<String, IList<String>>>(
      const IMap.empty(),
      (acc, entry) => acc.update(
        entry.category,
        (list) => list.add(entry.emoji),
        ifAbsent: () => IList([entry.emoji]),
      ),
    );

    final keywordMap = entries.fold<IMap<String, IList<String>>>(
      const IMap.empty(),
      (acc, entry) => acc.add(
        entry.emoji,
        IList<String>([...entry.tags, ...entry.aliases, entry.description]),
      ),
    );

    final customCategories = IMap.fromEntries(
      categoryMap.entries.map(
        (entry) => MapEntry(
          entry.key,
          EmojiCategory(
            name: entry.key,
            icon: switch (entry.key) {
              "Smileys & Emotion" => Icons.emoji_emotions,
              "People & Body" => Icons.emoji_people,
              "Animals & Nature" => Icons.emoji_nature,
              "Food & Drink" => Icons.emoji_food_beverage,
              "Travel & Places" => Icons.travel_explore,
              "Activities" => Icons.sports_soccer,
              "Objects" => Icons.emoji_objects,
              "Symbols" => Icons.emoji_symbols,
              "Flags" => Icons.emoji_flags,
              _ => Icons.category,
            },
            emojis: entry.value.toList(growable: false),
          ),
        ),
      ),
    );

    final customKeywords = IMap(
      Map.fromEntries(
        keywordMap.entries.map(
          (e) => MapEntry(e.key, e.value.toList(growable: false)),
        ),
      ),
    );

    return (customCategories, customKeywords);
  }

  static final provider =
      AsyncNotifierProvider.autoDispose<EmojiController, EmojiTuple>(
        EmojiController.new,
      );
}
