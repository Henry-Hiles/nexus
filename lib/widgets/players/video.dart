import "dart:async";

import "package:better_player/better_player.dart";
import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/helpers/extensions/save_attachment.dart";
import "package:nexus/models/info/video.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:nexus/widgets/players/player_controls.dart";

class const VideoPlayer(
  final Uri uri,
  final VideoInfo? info, {
  final bool encrypted = false,
  final String? filename,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aspectRatio = switch (info) {
      VideoInfo(:final width?, :final height?) when width > 0 && height > 0 =>
        width / height,
      _ => 16 / 9,
    };

    final loaded = useState(false);
    final controller = useMemoized(
      () => BetterPlayerController(
        PlayerConfiguration(
          aspectRatio: aspectRatio,
          fit: .contain,
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: .custom,
            customControlsBuilder: (controller, _) => HookBuilder(
              builder: (context) {
                final isLoaded = useValueListenable(loaded);
                final value = useState(controller.videoPlayerValue);
                useEffect(() {
                  void listener() => value.value = controller.videoPlayerValue;
                  controller.addVideoListener(listener);
                  return () => controller.removeVideoListener(listener);
                }, [controller]);

                final playing = value.value?.isPlaying ?? false;

                // better_player doesn't use material_ui, so this Material is needed.
                return Material(
                  type: .transparency,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: .opaque,
                          onTap: isLoaded
                              ? playing
                                    ? controller.pause
                                    : controller.play
                              : null,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed: () => context.saveAttachment(
                            ref,
                            uri,
                            encrypted: encrypted,
                            filename: filename,
                          ),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black38,
                          ),
                          tooltip: "Download",
                          icon: Icon(Icons.download),
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
                              playing: playing,
                              buffering: value.value?.isBuffering ?? false,
                              position: value.value?.position ?? .zero,
                              duration: value.value?.duration ?? .zero,
                              onPlayPause: playing
                                  ? controller.pause
                                  : controller.play,
                              onSeek: controller.seekTo,
                              loading: !isLoaded,
                              size: info?.size,
                              color: Colors.white,
                              actions: .new([
                                IconButton(
                                  onPressed: controller.toggleFullScreen,
                                  color: Colors.white,
                                  tooltip: controller.isFullScreen
                                      ? "Exit fullscreen"
                                      : "Fullscreen",
                                  icon: Icon(
                                    controller.isFullScreen
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    useEffect(() {
      scheduleMicrotask(() async {
        final video = await ref
            .read(ClientController.provider.notifier)
            .downloadMedia(.new(mxc: uri, encrypted: encrypted));
        if (!context.mounted) return;
        await controller.setupDataSource(.file(video.path));
        if (context.mounted) loaded.value = true;
      });

      return null;
    }, []);

    return ConstrainedBox(
      constraints: const .new(maxHeight: 300),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: .circular(12),
          child: BetterPlayer(controller: controller),
        ),
      ),
    );
  }
}
