import "dart:io";
import "dart:ui" as ui;

import "package:flutter/widgets.dart";
import "package:flutter_avif/flutter_avif.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/requests/download_media.dart";

class MxcImage(final WidgetRef ref, final DownloadMediaRequest request)
    extends ImageProvider<MxcImage> {
  @override
  Future<MxcImage> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(MxcImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _loadAsync(decode), scale: 1.0);

  Future<ui.Codec> _loadAsync(ImageDecoderCallback decode) async {
    final file = await ref
        .read(ClientController.provider.notifier)
        .downloadMedia(request);
    final bytes = await File(file.path).readAsBytes();

    // Flutter can't decode AVIF on Linux/Windows (or older Android/iOS), so we do it ourselves
    final avifType = isAvifFile(bytes.sublist(0, 16.clamp(0, bytes.length)));
    if (avifType != .unknown) {
      final codec = avifType == .avif
          ? SingleFrameAvifCodec(bytes: bytes)
          : MultiFrameAvifCodec(key: hashCode, avifBytes: bytes);
      await codec.ready();
      return AvifCodecAdapter(codec);
    }

    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is MxcImage && other.request == request;

  @override
  int get hashCode => request.hashCode;
}

class AvifCodecAdapter(final AvifCodec codec) implements ui.Codec {
  @override
  int get frameCount => codec.frameCount;

  @override
  int get repetitionCount => frameCount > 1 ? -1 : 0;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    final frame = await codec.getNextFrame();
    return AvifFrameInfo(frame.duration, frame.image);
  }

  @override
  void dispose() => codec.dispose();
}

class AvifFrameInfo(
  @override final Duration duration,
  @override final ui.Image image,
) implements ui.FrameInfo;
