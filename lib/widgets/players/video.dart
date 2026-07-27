import "dart:async";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/info/video.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";

class VideoPlayer extends HookConsumerWidget {
  final VideoInfo? info;
  final Uri uri;
  final bool encrypted;
  const VideoPlayer(this.uri, this.info, {this.encrypted = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = useMemoized(
      () => Player(configuration: .new(bufferSize: 128 * 1024 * 1024)),
    );
    final controller = useMemoized(() => VideoController(player));

    useEffect(() {
      player.platform?.state = player.platform!.state.copyWith(buffering: true);
      scheduleMicrotask(() async {
        final video = await ref
            .watch(ClientController.provider.notifier)
            .downloadMedia(.new(mxc: uri, encrypted: encrypted));
        await player.open(Media(video.path), play: false);
      });

      return player.dispose;
    }, []);

    return SizedBox(height: 300, child: Video(controller: controller));
  }
}
