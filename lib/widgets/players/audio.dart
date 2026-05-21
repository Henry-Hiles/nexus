import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:media_kit/media_kit.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/models/info/audio.dart";

class AudioPlayer extends HookConsumerWidget {
  final Uri url;
  final AudioInfo? info;

  const AudioPlayer(this.url, this.info, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = useMemoized(
      () => Player(
        configuration: PlayerConfiguration(bufferSize: 128 * 1024 * 1024),
      ),
    );

    final playing = useState(false);
    final position = useState(Duration.zero);
    final duration = useState(Duration.zero);

    useEffect(() {
      scheduleMicrotask(() async {
        await player.open(
          Media(url.toString(), httpHeaders: ref.headers),
          play: false,
        );

        player.stream.playing.listen((value) {
          playing.value = value;
        });

        player.stream.position.listen((value) {
          position.value = value;
        });

        player.stream.duration.listen((value) {
          duration.value = value;
        });
      });

      return player.dispose;
    }, []);

    String format(Duration duration) {
      final minutes = duration.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, "0");
      final seconds = duration.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, "0");

      return "$minutes:$seconds";
    }

    return SizedBox(
      height: 60,
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
          padding: EdgeInsetsGeometry.only(left: 8, right: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: player.playOrPause,
                icon: Icon(
                  playing.value ? Icons.pause_circle : Icons.play_circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                format(position.value),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Expanded(
                child: Slider(
                  min: 0,
                  max: duration.value.inMilliseconds <= 0
                      ? 1
                      : duration.value.inMilliseconds.toDouble(),
                  value: position.value.inMilliseconds.toDouble(),
                  onChanged: (value) =>
                      player.seek(Duration(milliseconds: value.toInt())),
                ),
              ),
              Text(
                format(duration.value),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
