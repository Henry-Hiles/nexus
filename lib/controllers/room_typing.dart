import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/controllers/typing.dart";

/// The other users typing in a room, or none if typing indicators are hidden
/// in settings.
class RoomTypingController(final String roomId)
    extends Notifier<IList<String>> {
  @override
  IList<String> build() {
    final shouldShow = ref.watch(
      SettingsController.provider.select(
        (settings) => settings.value?.typingIndicators != .neither,
      ),
    );
    if (!shouldShow) return const .empty();

    final userId = ref.watch(
      ClientStateController.provider.select((state) => state?.userId),
    );

    return ref
            .watch(TypingController.provider.select((typing) => typing[roomId]))
            ?.remove(userId ?? "") ??
        const .empty();
  }

  static final provider = NotifierProvider.family
      .autoDispose<RoomTypingController, IList<String>, String>(
        RoomTypingController.new,
      );
}
