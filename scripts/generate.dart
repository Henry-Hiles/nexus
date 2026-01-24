import "dart:io";
import "package:ffigen/ffigen.dart";
import "package:path/path.dart";

void main(List<String> args) async {
  final buildDir = Directory.fromUri(
    Platform.script.resolve(join("..", "build", "gomuks")),
  );
  if (!await buildDir.exists()) await buildDir.create(recursive: true);

  final repoDir = Directory(join(buildDir.path, "source"));

  var skipBuild = args.contains("--skip");

  final generatedSourcePath = join("src", "third_party", "gomuks.g.dart");
  final generatedLibPath = Platform.script.resolve(
    join("..", "lib", generatedSourcePath),
  );
  final bindingsFile = File(generatedLibPath.toFilePath());

  if (await bindingsFile.exists() && await repoDir.exists()) {
    final result = await Process.run("git", [
      "fetch",
      "--dry-run",
    ], workingDirectory: repoDir.path);

    if ((result.stdout as String).trim().isEmpty) {
      skipBuild = true;
    }
  }

  if (!skipBuild) {
    if (await repoDir.exists()) await repoDir.delete(recursive: true);

    print("Cloning Gomuks repository...");
    final cloneResult = await Process.run("git", [
      "clone",
      "--branch",
      "tulir/ffi",
      "--depth",
      "1",
      "https://mau.dev/gomuks/gomuks",
      repoDir.path,
    ]);

    if (cloneResult.exitCode != 0) {
      throw Exception(
        "Failed to clone Gomuks repository: \n${cloneResult.stderr}",
      );
    }

    for (final name in ["libgomuks.so", "libgomuks.dylib", "libgomuks.dll"]) {
      final libFile = File(join(buildDir.path, name));

      print("Building Gomuks shared library $name...");
      final result = await Process.run("go", [
        "build",
        "-o",
        libFile.path,
        "-buildmode=c-shared",
      ], workingDirectory: join(repoDir.path, "pkg/ffi"));

      if (result.exitCode != 0) {
        throw Exception(
          "Failed to build Gomuks shared library\n${result.stderr}",
        );
      }
    }
  }

  print("Generating FFI Bindings...");
  final packageRoot = Platform.script.resolve("../");
  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve("lib/src/third_party/gomuks.g.dart"),
    ),
    headers: Headers(
      entryPoints: [File(join(buildDir.path, "libgomuks.h")).uri],
      // compilerOptions: ["-I${String.fromEnvironment("CPATH")}"],
    ),
    functions: Functions.includeAll,
  ).generate();
  print("Done!");
}
