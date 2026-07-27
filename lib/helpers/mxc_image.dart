import "dart:ui";
import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/requests/download_media.dart";

class MxcImage extends ImageProvider<MxcImage> {
  final WidgetRef ref;
  final DownloadMediaRequest request;
  const MxcImage(this.ref, this.request);

  @override
  Future<MxcImage> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(MxcImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _loadAsync(decode), scale: 1.0);

  Future<Codec> _loadAsync(ImageDecoderCallback decode) async {
    final file = await ref
        .read(ClientController.provider.notifier)
        .downloadMedia(request);
    final buffer = await ImmutableBuffer.fromFilePath(file.path);

    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is MxcImage && other.request == request;

  @override
  int get hashCode => request.hashCode;
}
