import "dart:io";
import "package:hooks/hooks.dart";
import "package:code_assets/code_assets.dart";
import "package:path/path.dart";
import "package:ffigen/ffigen.dart";

Future<void> main(List<String> args) => build(args, (input, output) async {
  final targetOS = input.config.code.targetOS;
  final targetArch = input.config.code.targetArchitecture;
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

  // Where we put the Gomuks repo and compiled library
  final buildDir = Directory.fromUri(
    input.outputDirectoryShared.resolve("gomuks/"),
  );
  if (!await buildDir.exists()) await buildDir.create(recursive: true);

  final repoDir = Directory(join(buildDir.path, "source"));

  bool skipBuild = false;

  final generatedSourcePath = "src/third_party/gomuks.g.dart";
  final generatedLibPath = input.packageRoot.resolve(
    join("lib", generatedSourcePath),
  );
  final bindingsFile = File(generatedLibPath.toFilePath());

  if (await bindingsFile.exists() &&
      await File(join(buildDir.path, libFileName)).exists() &&
      await repoDir.exists()) {
    final result = await Process.run("git", [
      "fetch",
      "--dry-run",
    ], workingDirectory: repoDir.path);

    if ((result.stdout as String).trim().isEmpty) {
      skipBuild = true;
    }
  }

  if (skipBuild) {
    return print(
      "Gomuks build skipped: bindings and library exist and repo is up to date.",
    );
  }

  if (await repoDir.exists()) await repoDir.delete(recursive: true);

  print("Cloning Gomuks repository...");
  final cloneResult = await Process.run("git", [
    "clone",
    "--depth",
    "1",
    "--branch",
    "tulir/ffi",
    "https://mau.dev/gomuks/gomuks",
    repoDir.path,
  ]);
  if (cloneResult.exitCode != 0) {
    throw Exception(
      "Failed to clone Gomuks repository: \n${cloneResult.stderr}",
    );
  }

  final libFile = File(join(buildDir.path, libFileName));

  print("Building Gomuks shared library for $targetOS/$targetArch...");
  final result = await Process.run("go", [
    "build",
    "-o",
    libFile.path,
    "-buildmode=c-shared",
  ], workingDirectory: join(repoDir.path, "pkg/ffi"));

  if (result.exitCode != 0) {
    throw Exception("Failed to build Gomuks shared library\n${result.stderr}");
  }

  // Add the library as a code asset so Dart can find it
  output.assets.code.add(
    CodeAsset(
      package: "nexus",
      name: "src/third_party/gomuks.g.dart",
      linkMode: DynamicLoadingBundled(),
      file: libFile.uri,
    ),
  );
  output.dependencies.add(libFile.uri);

  print("Generating FFI Bindings...");
  FfiGenerator(
    output: Output(dartFile: generatedLibPath),
    headers: Headers(
      entryPoints: [File(join(buildDir.path, "libgomuks.h")).uri],
    ),
    functions: Functions.includeAll,
  ).generate();
});
