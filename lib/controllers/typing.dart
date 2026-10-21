import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/typing.dart";

class TypingController extends Notifier<IMap<String, IList<String>>> {
  @override
  IMap<String, IList<String>> build() => .new();

  void set(Typing typing) => state = state.add(typing.roomId, typing.userIds);

  static final provider =
      NotifierProvider<TypingController, IMap<String, IList<String>>>(
        TypingController.new,
      );
}
