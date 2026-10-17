import "dart:async";
import "dart:io";
import "dart:isolate";
import "dart:ui" as ui;

import "package:avif_native/avif_native.dart";
import "package:flutter/widgets.dart";
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
    if (String.fromCharCodes(bytes.skip(4).take(8))
        case "ftypavif" || "ftypavis") {
      return AvifCodec(await Isolate.run(() => decodeAvif(bytes)));
    }

    return decode(await .fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is MxcImage && other.request == request;

  @override
  int get hashCode => request.hashCode;
}

class AvifCodec(final AvifImageData data) implements ui.Codec {
  var _frameIndex = 0;

  @override
  int get frameCount => data.frames.length;

  // libavif uses -2 for unknown, which we treat as infinite like browsers do
  @override
  int get repetitionCount =>
      data.repetitionCount < 0 ? -1 : data.repetitionCount;

  @override
  Future<ui.FrameInfo> getNextFrame() {
    final frame = data.frames[_frameIndex++ % frameCount];
    final completer = Completer<ui.FrameInfo>();
    ui.decodeImageFromPixels(
      frame.rgba,
      frame.width,
      frame.height,
      .rgba8888,
      (image) => completer.complete(AvifFrameInfo(frame.duration, image)),
    );
    return completer.future;
  }

  @override
  void dispose() {}
}

class AvifFrameInfo(
  @override final Duration duration,
  @override final ui.Image image,
) implements ui.FrameInfo;
