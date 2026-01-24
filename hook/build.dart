import "package:hooks/hooks.dart";
import "package:code_assets/code_assets.dart";
import "package:path/path.dart";

Future<void> main(List<String> args) => build(args, (input, output) async {
  final targetOS = input.config.code.targetOS;
  String libFileName;
  switch (targetOS) {
    case OS.linux:
      libFileName = "libgomuks.so";
      break;
    case OS.macOS:
      libFileName = "libgomuks.dylib";
      break;
    case OS.windows:
      libFileName = "libgomuks.dll";
      break;
    default:
      throw UnsupportedError("Unsupported OS: $targetOS");
  }

  final generatedFile = join("src", "third_party", "gomuks.g.dart");
  output.assets.code.add(
    CodeAsset(
      package: "nexus",
      name: generatedFile,
      linkMode: DynamicLoadingBundled(),
      file: input.packageRoot.resolve(join("build", "gomuks", libFileName)),
    ),
  );
  output.dependencies.add(
    input.packageRoot.resolve(join("lib", generatedFile)),
  );
});
