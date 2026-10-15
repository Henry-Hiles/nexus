import "dart:async";

import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/info/video.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";
import "package:nexus/widgets/players/player_controls.dart";

class const VideoPlayer(
  final Uri uri,
  final VideoInfo? info, {
  final bool encrypted = false,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = useMemoized(
      () => Player(configuration: .new(bufferSize: 128 * 1024 * 1024)),
    );
    final controller = useMemoized(() => VideoController(player));
    final loaded = useState(false);

    useEffect(() {
      scheduleMicrotask(() async {
        final video = await ref
            .read(ClientController.provider.notifier)
            .downloadMedia(.new(mxc: uri, encrypted: encrypted));
        await player.open(Media(video.path), play: false);
        if (context.mounted) loaded.value = true;
      });

      return player.dispose;
    }, []);

    final aspectRatio = switch (info) {
      VideoInfo(:final width?, :final height?) when width > 0 && height > 0 =>
        width / height,
      _ => 16 / 9,
    };

    return ConstrainedBox(
      constraints: const .new(maxHeight: 300),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: .circular(12),
          child: Video(
            controller: controller,
            controls: (_) =>
                // Until media_kit moves to material_ui, this Material is needed.
                Material(
                  type: .transparency,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: .opaque,
                          onTap: loaded.value ? player.playOrPause : null,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: .bottomCenter,
                              end: .topCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                          child: Padding(
                            padding: const .only(left: 4, right: 4, top: 16),
                            child: PlayerControls(
                              player,
                              loading: !loaded.value,
                              color: Colors.white,
                              actions: .new([
                                Builder(
                                  builder: (context) {
                                    final fullscreen = isFullscreen(context);

                                    return IconButton(
                                      onPressed: () =>
                                          toggleFullscreen(context),
                                      color: Colors.white,
                                      tooltip: fullscreen
                                          ? "Exit fullscreen"
                                          : "Fullscreen",
                                      icon: Icon(
                                        fullscreen
                                            ? Icons.fullscreen_exit
                                            : Icons.fullscreen,
                                      ),
                                    );
                                  },
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
