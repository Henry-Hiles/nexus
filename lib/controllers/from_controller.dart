import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";

class FromController extends Notifier<String?> {
  FromController(_);
  @override
  String? build() => null;

  void set(String? value) => state = value;

  static final provider =
      NotifierProvider.family<FromController, String?, Room>(
        FromController.new,
      );
}
