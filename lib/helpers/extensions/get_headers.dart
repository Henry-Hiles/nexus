import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/header_controller.dart";

extension GetHeaders on WidgetRef {
  Map<String, String> get headers =>
      watch(HeaderController.provider).requireValue;
}
