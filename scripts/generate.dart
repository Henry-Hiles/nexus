import "dart:io";
import "package:ffigen/ffigen.dart";
import "package:path/path.dart";

void main(List<String> args) async {
  final repoDir = Directory.fromUri(Platform.script.resolve("../gomuks"));

  print("Generating FFI Bindings...");

  final libclangPath = Platform.environment["LIBCLANG_PATH"];
  FfiGenerator(
    output: Output(
      dartFile: Platform.script.resolve("../lib/src/third_party/gomuks.g.dart"),
    ),
    headers: Headers(
      entryPoints: [File(join(repoDir.path, "pkg", "ffi", "gomuksffi.h")).uri],
      compilerOptions: ["--no-warnings"],
    ),
    functions: Functions.includeAll,
  ).generate(
    libclangDylib: libclangPath == null
        ? null
        : Uri.file(join(libclangPath, "libclang.so")),
  );
  print("Done!");
}
