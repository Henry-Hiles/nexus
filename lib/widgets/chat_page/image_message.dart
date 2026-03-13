import "dart:math";
import "package:cross_cache/cross_cache.dart";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flyer_chat_image_message/flyer_chat_image_message.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";

class ExpandableImageMessage extends ConsumerWidget {
  final ImageMessage message;
  final int index;

  const ExpandableImageMessage(this.message, {required this.index, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
    onTap: () => showDialog(
      context: context,
      builder: (_) => LayoutBuilder(
        builder: (context, constraints) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(constraints.maxWidth / 100),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: min(constraints.maxWidth, 1000),
            ),
            child: InteractiveViewer(
              child: Image(
                fit: BoxFit.contain,
                image: CachedNetworkImage(
                  message.source,
                  ref.watch(CrossCacheController.provider),
                  headers: ref.headers,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
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
