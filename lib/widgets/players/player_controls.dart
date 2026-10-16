import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:media_kit/media_kit.dart";

/// Play/pause, position and seeking controls for a media_kit [Player].
class const PlayerControls(
  final Player player, {
  final bool loading = false,
  final Color? color,
  final IList<Widget> actions = const .empty(),
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final playing = useStream(
      player.stream.playing,
      initialData: player.state.playing,
    ).requireData;
    final buffering = useStream(
      player.stream.buffering,
      initialData: player.state.buffering,
    ).requireData;
    final position = useStream(
      player.stream.position,
      initialData: player.state.position,
    ).requireData;
    final duration = useStream(
      player.stream.duration,
      initialData: player.state.duration,
    ).requireData;

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

    final textStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: color);
    final max = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();

    final playButton = loading || buffering
        ? SizedBox.square(
            dimension: 48,
            child: CircularProgressIndicator(padding: .all(12), color: color),
          )
        : IconButton(
            onPressed: player.playOrPause,
            color: color,
            tooltip: playing ? "Pause" : "Play",
            icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
          );

    Slider slider({EdgeInsetsGeometry? padding}) => Slider(
      padding: padding,
      max: max,
      value: min(position.inMilliseconds.toDouble(), max),
      onChanged: loading
          ? null
          : (value) => player.seek(.new(milliseconds: value.toInt())),
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 300
          ? Column(
              mainAxisSize: .min,
              children: [
                slider(padding: const .symmetric(horizontal: 12)),
                Row(
                  children: [
                    playButton,
                    Expanded(
                      child: Text(
                        "${format(position)} / ${format(duration)}",
                        style: textStyle,
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                playButton,
                SizedBox(width: 8),
                Text(format(position), style: textStyle),
                Expanded(child: slider()),
                Text(format(duration), style: textStyle),
                ...actions,
              ],
            ),
    );
  }
}
