import "dart:io";
import "package:ffigen/ffigen.dart";
import "package:path/path.dart";

void main(List<String> args) async {
  final repoDir = Directory.fromUri(
    Platform.script.resolve("../src/gomuks/source"),
  );
  if (await repoDir.exists()) await repoDir.delete(recursive: true);
  await repoDir.create(recursive: true);

  print("Cloning Gomuks repository...");
  final cloneResult = await Process.run("git", [
    "clone",
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

  print("Generating FFI Bindings...");
  FfiGenerator(
    output: Output(
      dartFile: Platform.script.resolve("../lib/src/third_party/gomuks.g.dart"),
    ),
    headers: Headers(
      entryPoints: [File(join(repoDir.path, "pkg", "ffi", "gomuksffi.h")).uri],
      compilerOptions: ["--no-warnings"],
    ),
    functions: Functions.includeAll,
  ).generate();
  print("Done!");
}
