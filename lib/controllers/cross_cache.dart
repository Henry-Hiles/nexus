import "package:cross_cache/cross_cache.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class CrossCacheController extends Notifier<CrossCache> {
  @override
  CrossCache build() => .new();

  static final provider = NotifierProvider<CrossCacheController, CrossCache>(
    CrossCacheController.new,
  );
}
