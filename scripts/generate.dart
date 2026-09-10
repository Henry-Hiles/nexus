import "dart:io";

import "package:ffigen/ffigen.dart";
import "package:path/path.dart";
import "package:nexus/helpers/extensions/get_xcode_sdk.dart";

void main(List<String> args) async {
  final repoDir = Directory.fromUri(Platform.script.resolve("../gomuks"));

  print("Generating FFI Bindings...");

  final libclangPath = Platform.environment["LIBCLANG_PATH"];
  FfiGenerator(
    output: .new(
      dart: .new(
        path: Platform.script.resolve("../lib/src/third_party/gomuks.g.dart"),
      ),
    ),
    visitors: [.new(func: (node) => node.isIncluded = true)],
    input: .new(
      entryPoints: [File(join(repoDir.path, "pkg", "ffi", "gomuksffi.h")).uri],
      compilerOptions: [
        "--no-warnings",
        if (Platform.isMacOS) "-I${await getXCodeTool()}/usr/include",
      ],
    ),
  ).generate(
    libclangDylib: libclangPath == null
        ? null
        : Uri.file(
            join(
              libclangPath,
              "libclang.${(Platform.isLinux || Platform.isAndroid)
                  ? "so"
                  : Platform.isMacOS
                  ? "dylib"
                  : Platform.isWindows
                  ? "dll"
                  : throw UnsupportedError("Unsupported Platform")}",
            ),
          ),
  );
  print("Done!");
}
