import "dart:async";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/models/info/video.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";
import "package:nexus/helpers/extensions/get_headers.dart";

class VideoPlayer extends HookConsumerWidget {
  final VideoInfo? info;
  final Uri url;
  const VideoPlayer(this.url, this.info, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = useMemoized(
      () => Player(
        configuration: PlayerConfiguration(bufferSize: 128 * 1024 * 1024),
      ),
    );
    final controller = useMemoized(() => VideoController(player));

    useEffect(() {
      scheduleMicrotask(
        () => player.open(
          Media(url.toString(), httpHeaders: ref.headers),
          play: false,
        ),
      );

      return player.dispose;
    }, []);

    return SizedBox(height: 300, child: Video(controller: controller));
  }
}
