import "dart:io";
import "package:hooks/hooks.dart";
import "package:code_assets/code_assets.dart";

Future<void> main(List<String> args) => build(args, (input, output) async {
  final codeConfig = input.config.code;
  final targetOS = codeConfig.targetOS;
  final targetArch = codeConfig.targetArchitecture;

  String libFileName;
  Map<String, String> env = {};
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
    case OS.android:
      libFileName = "libgomuks.so";

      final targetNdkApi = codeConfig.android.targetNdkApi;

      final ndkHome =
          Platform.environment["ANDROID_NDK_HOME"] ??
          Platform.environment["ANDROID_NDK_ROOT"] ??
          Platform.environment["NDK_HOME"] ??
          await _findNdkFromSdk();
      if (ndkHome == null) {
        throw Exception(
          "Could not find Android NDK. Set ANDROID_NDK_HOME or install via sdkmanager.",
        );
      }

      final hostTag = _ndkHostTag();
      final (goArch, ccTriple) = _androidArch(targetArch);
      final cc =
          "$ndkHome/toolchains/llvm/prebuilt/$hostTag/bin/$ccTriple$targetNdkApi-clang";

      env = {"CGO_ENABLED": "1", "GOOS": "android", "GOARCH": goArch, "CC": cc};
      break;
    default:
      throw UnsupportedError("Unsupported OS: $targetOS");
  }

  var libFile = input.packageRoot.resolve(libFileName);
  final gomuksBuildDir = input.packageRoot.resolve("gomuks/");

  if (!(await File.fromUri(libFile).exists())) {
    final buildDir = input.packageRoot.resolve("build/");
    libFile = buildDir.resolve("${targetArch.name}/$libFileName");

    // goheif/dav1d supported on Android would need to fix upstream
    final tags = targetOS == OS.android ? "goolm,noheic" : "goolm";

    print(
      "Building Gomuks shared library $libFileName (${targetOS.name}/${targetArch.name}) from source...",
    );
    final result = await Process.run(
      "go",
      ["build", "-tags", tags, "-o", libFile.path, "-buildmode=c-shared"],
      workingDirectory: gomuksBuildDir.resolve("pkg/ffi/").toFilePath(),
      environment: env.isNotEmpty ? env : null,
    );

    if (result.exitCode != 0) {
      throw Exception(
        "Failed to build Gomuks shared library\n${result.stderr}",
      );
    }
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
    ..dependencies.add(libFile)
    ..dependencies.add(gomuksBuildDir);
  print("Done!");
});

Future<String?> _findNdkFromSdk() async {
  // pretty sure this wont be needed with nix, i'll get this removed
  final androidHome =
      Platform.environment["ANDROID_HOME"] ??
      Platform.environment["ANDROID_SDK_ROOT"];
  if (androidHome == null) return null;
  final ndkDir = Directory("$androidHome/ndk");
  if (!await ndkDir.exists()) return null;
  final versions = await ndkDir.list().toList();
  if (versions.isEmpty) return null;
  versions.sort((a, b) => a.path.compareTo(b.path));
  return versions.last.path;
}

String _ndkHostTag() {
  if (Platform.isMacOS) {
    return "darwin-x86_64";
  } else if (Platform.isLinux) {
    return "linux-x86_64";
  } else if (Platform.isWindows) {
    return "windows-x86_64";
  }
  throw UnsupportedError("Unsupported host platform for Android NDK");
}

(String goArch, String ccTriple) _androidArch(Architecture arch) {
  switch (arch) {
    case Architecture.arm64:
      return ("arm64", "aarch64-linux-android");
    case Architecture.arm:
      return ("arm", "armv7a-linux-androideabi");
    case Architecture.x64:
      return ("amd64", "x86_64-linux-android");
    case Architecture.ia32:
      return ("386", "i686-linux-android");
    default:
      throw UnsupportedError("Unsupported Android architecture: $arch");
  }
}
