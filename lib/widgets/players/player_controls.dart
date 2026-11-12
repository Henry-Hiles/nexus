import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/size_to_string.dart";

/// Play/pause, position and seeking controls, for any player.
class const PlayerControls({
  required final bool playing,
  required final Duration position,
  required final Duration duration,
  required final VoidCallback onPlayPause,
  required final ValueChanged<Duration> onSeek,
  final bool loading = false,
  final bool buffering = false,
  final Color? color,
  final int? size,
  final IList<Widget> actions = const .empty(),
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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

    final sizeSuffix = size == null ? "" : " (${size!.sizeAsString})";

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
            onPressed: onPlayPause,
            color: color,
            tooltip: playing ? "Pause" : "Play",
            icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
          );

    Slider slider({EdgeInsetsGeometry? padding}) => .new(
      padding: padding,
      max: max,
      value: min(position.inMilliseconds.toDouble(), max),
      onChanged: loading
          ? null
          : (value) => onSeek(.new(milliseconds: value.toInt())),
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 300
          ? Column(
              mainAxisSize: .min,
              children: [
                SizedBox(height: 12),
                slider(padding: const .symmetric(horizontal: 16)),
                Row(
                  children: [
                    playButton,
                    Expanded(
                      child: Text(
                        "${format(position)} / ${format(duration)}$sizeSuffix",
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
          : IntrinsicHeight(
              child: Row(
                children: [
                  playButton,
                  SizedBox(width: 8),
                  Text(format(position), style: textStyle),
                  Expanded(child: slider()),
                  Text("${format(duration)}$sizeSuffix", style: textStyle),
                  ...actions,
                ],
              ),
            ),
    );
  }
}
