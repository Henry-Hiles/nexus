import "dart:io";
import "dart:ui" as ui;

import "package:flutter/rendering.dart";
import "package:flutter_test/flutter_test.dart";
import "package:nexus/controllers/client.dart";

import "screenshot_data.dart";

/// Answers the commands the screenshotted screens send to gomuks, so the
/// screenshots don't need gomuks or a homeserver.
class FakeClientController() extends ClientController {
  this : super(null);

  @override
  Future<int> build() async => 0;

  @override
  Future<dynamic> sendCommand(
    String command, [
    Map<String, dynamic> request = const {},
  ]) async => switch (command) {
    "get_url_preview" => ScreenshotData.urlPreview,
    "download_media" => {"path": _mediaPath(request["mxc"])},
    "get_related_events" => [],
    "mark_read" || "set_typing" => null,
    _ => throw UnimplementedError("The screenshots can't answer $command"),
  };

  /// The file for [mxc], from avatars/ beside this file
  static String _mediaPath(String mxc) {
    final file = File(switch (mxc) {
      ScreenshotData.nexusAvatar => "assets/mobile.png",
      _ =>
        "integration_test/screenshots/avatars/"
            "${Uri.parse(mxc).pathSegments.last}",
    });
    if (!file.existsSync()) throw StateError("No screenshot media for $mxc");
    return file.absolute.path;
  }
}

extension Screenshot on WidgetTester {
  /// Saves what the app currently shows to [path], as a PNG.
  Future<void> screenshot(String path) async {
    // Lets images finish decoding and animations settle
    for (var frame = 0; frame < 20; frame++) {
      await runAsync(() => .delayed(const .new(milliseconds: 50)));
      await pump(const .new(milliseconds: 50));
    }

    final renderView = binding.renderViews.single;
    final layer = renderView.debugLayer! as OffsetLayer;
    final bytes = await runAsync(() async {
      final image = await layer.toImage(Offset.zero & view.physicalSize);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });

    await File(path).create(recursive: true);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
  }
}
