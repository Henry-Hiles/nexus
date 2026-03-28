import "package:cross_cache/cross_cache.dart";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flyer_chat_image_message/flyer_chat_image_message.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/widgets/chat_page/expandable_image.dart";

class ExpandableImageMessage extends ConsumerWidget {
  final ImageMessage message;
  final int index;

  const ExpandableImageMessage(this.message, {required this.index, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExpandableImage(
    message.source,
    child: FlyerChatImageMessage(
      customImageProvider: CachedNetworkImage(
        message.source,
        ref.watch(CrossCacheController.provider),
        headers: ref.headers,
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(
          "Image Failed to Load",
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      message: message,
      index: index,
    ),
  );
}
