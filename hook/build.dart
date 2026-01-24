import "dart:io";
import "package:hooks/hooks.dart";
import "package:code_assets/code_assets.dart";

Future<void> main(List<String> args) => build(args, (input, output) async {
  final buildDir = input.packageRoot.resolve("src/");
  if (await File(buildDir.resolve("lock").toFilePath()).exists()) return;

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

  final gomuksBuildDir = buildDir.resolve("gomuks/");
  final libFile = gomuksBuildDir.resolve(libFileName);

  print("Building Gomuks shared library $libFileName...");
  final result = await Process.run("go", [
    "build",
    "-o",
    libFile.path,
    "-buildmode=c-shared",
  ], workingDirectory: gomuksBuildDir.resolve("source/pkg/ffi/").toFilePath());

  if (result.exitCode != 0) {
    throw Exception("Failed to build Gomuks shared library\n${result.stderr}");
  }

  final generatedFile = "src/third_party/gomuks.g.dart";
  print("Adding $libFileName as asset...");
  output
    ..assets.code.add(
      CodeAsset(
        package: "nexus",
        name: generatedFile,
        linkMode: DynamicLoadingBundled(),
        file: libFile,
      ),
    )
    ..dependencies.add(libFile);
  print("Done!");
});
