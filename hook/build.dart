import "dart:io";
import "package:hooks/hooks.dart";
import "package:code_assets/code_assets.dart";
import "package:path/path.dart";
import "package:ffigen/ffigen.dart";

Future<void> main(List<String> args) => build(args, (input, output) async {
  output.assets.code.add(
    CodeAsset(
      package: "nexus",
      name: "src/third_party/gomuks.g.dart",
      linkMode: DynamicLoadingBundled(),
      file: libFile.uri,
    ),
  );
  output.dependencies.add(libFile.uri);
});
