import "dart:async";

import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:media_kit/media_kit.dart";
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
    final player = useMemoized(
      () => Player(configuration: .new(bufferSize: 128 * 1024 * 1024)),
    );
    final loaded = useState(false);

    useEffect(() {
      scheduleMicrotask(() async {
        final audio = await ref
            .read(ClientController.provider.notifier)
            .downloadMedia(.new(mxc: uri, encrypted: encrypted));
        if (!context.mounted) return;
        await player.open(Media(audio.path), play: false);
        if (context.mounted) loaded.value = true;
      });

      return player.dispose;
    }, []);

    return SizedBox(
      height: 60,
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
          padding: .symmetric(horizontal: 8),
          child: PlayerControls(
            player,
            loading: !loaded.value,
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
      ),
    );
  }
}
