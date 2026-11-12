import "dart:async";

import "package:audioplayers/audioplayers.dart" as audioplayers;
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/helpers/extensions/save_attachment.dart";
import "package:nexus/models/info/audio.dart";
import "package:nexus/widgets/players/player_controls.dart";

class const AudioPlayer(
  final Uri uri,
  final AudioInfo? info, {
  final bool encrypted = false,
  final String? filename,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = useMemoized(audioplayers.AudioPlayer.new);
    final loaded = useState(false);

    useEffect(() {
      scheduleMicrotask(() async {
        final audio = await ref
            .read(ClientController.provider.notifier)
            .downloadMedia(.new(mxc: uri, encrypted: encrypted));
        if (!context.mounted) return;
        // Keeps the audio loaded after it finishes, so it can be replayed
        await player.setReleaseMode(.stop);
        await player.setSource(audioplayers.DeviceFileSource(audio.path));
        if (context.mounted) loaded.value = true;
      });

      return player.dispose;
    }, []);

    final state = useStream(
      player.onPlayerStateChanged,
      initialData: player.state,
    ).requireData;
    final position = useStream(
      player.onPositionChanged,
      initialData: Duration.zero,
    ).requireData;
    final duration = useStream(
      player.onDurationChanged,
      initialData: Duration.zero,
    ).requireData;
    final playing = state == .playing;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: .symmetric(horizontal: 8),
        child: PlayerControls(
          playing: playing,
          position: position,
          duration: duration,
          onPlayPause: playing ? player.pause : player.resume,
          onSeek: player.seek,
          loading: !loaded.value,
          size: info?.size,
          actions: .new([
            SizedBox(width: 4),
            IconButton(
              onPressed: () => context.saveAttachment(
                ref,
                uri,
                encrypted: encrypted,
                filename: filename,
              ),
              tooltip: "Download",
              icon: Icon(Icons.download),
            ),
          ]),
        ),
      ),
    );
  }
}
