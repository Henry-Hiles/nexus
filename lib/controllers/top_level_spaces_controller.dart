import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class TopLevelSpacesController extends Notifier<IList<String>> {
  @override
  IList<String> build() => const IList.empty();

  void set(IList<String> newSpaces) => state = newSpaces;

  static final provider =
      NotifierProvider<TopLevelSpacesController, IList<String>>(
        TopLevelSpacesController.new,
      );
}
