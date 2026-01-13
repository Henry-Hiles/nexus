import "package:cross_cache/cross_cache.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class CrossCacheController extends Notifier<CrossCache> {
  static const String spaceKey = "space";
  static const String roomKey = "room";

  @override
  CrossCache build() => CrossCache();

  static final provider = NotifierProvider<CrossCacheController, CrossCache>(
    CrossCacheController.new,
  );
}
