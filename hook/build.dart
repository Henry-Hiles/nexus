import "dart:io";
import "package:collection/collection.dart";
import "package:hooks/hooks.dart";
import "package:code_assets/code_assets.dart";
import "package:nexus/helpers/extensions/get_xcode_sdk.dart";
import "package:path/path.dart";

Future<void> main(List<String> args) => build(args, (input, output) async {
  if (!input.config.buildCodeAssets) return;
  final codeConfig = input.config.code;
  final targetOS = codeConfig.targetOS;
  final targetArch = codeConfig.targetArchitecture;

  String libFileName;
  Map<String, String> extraEnv = {};
  switch (targetOS) {
    case OS.linux:
      libFileName = "libgomuks.so";
      break;
    case OS.macOS:
      libFileName = "libgomuks.dylib";
      extraEnv = {"SDKROOT": await getXCodeSDK()};
      break;
    case OS.windows:
      libFileName = "libgomuks.dll";
      break;
    case OS.android:
      libFileName = "libgomuks.so";

      final targetNdkApi = codeConfig.android.targetNdkApi;

      Future<String?> findNdkFromSdk() async {
        final androidHome =
            Platform.environment["ANDROID_HOME"] ??
            Platform.environment["ANDROID_SDK_ROOT"];
        if (androidHome == null) return null;

        final ndkDir = Directory(join(androidHome, "ndk"));
        if (!await ndkDir.exists()) return null;

        final versions = await ndkDir.list().toList();
        return versions.sortedBy((file) => file.path).lastOrNull?.path;
      }

      final ndkHome =
          Platform.environment["ANDROID_NDK_HOME"] ??
          Platform.environment["ANDROID_NDK_ROOT"] ??
          Platform.environment["NDK_HOME"] ??
          await findNdkFromSdk();

      if (ndkHome == null) {
        throw Exception(
          "Could not find Android NDK. Set ANDROID_NDK_HOME or install via sdkmanager.",
        );
      }

      // TODO: Someone please give me a way to detect host architecture so I can change this
      final hostTag =
          Platform.environment["ANDROID_HOST_TAG"] ??
          "${Platform.operatingSystem}-x86_64";
      final ccTriple = switch (targetArch) {
        Architecture.arm64 => "aarch64-linux-android",
        Architecture.arm => "armv7a-linux-androideabi",
        Architecture.x64 => "x86_64-linux-android",
        Architecture.ia32 => "i686-linux-android",
        _ => throw UnsupportedError(
          "Unsupported Android architecture: $targetArch",
        ),
      };
      final cc =
          "$ndkHome/toolchains/llvm/prebuilt/$hostTag/bin/$ccTriple$targetNdkApi-clang";

      extraEnv = {"GOOS": "android", "CC": cc};
      break;
    default:
      throw UnsupportedError("Unsupported OS: $targetOS");
  }

  var libFile = input.packageRoot.resolve(libFileName);
  final gomuksBuildDir = input.packageRoot.resolve("gomuks/");

  if (!(await File.fromUri(libFile).exists())) {
    final buildDir = input.packageRoot.resolve("build/");
    libFile = buildDir.resolve("${targetArch.name}/$libFileName");

    final tags = [
      "sqlite_fts5",
      "goolm",
      // goheif/dav1d is not supported on Android, would need to be fixed upstream
      if (targetOS == OS.android) "noheic",
    ].join(",");
    print(
      "Building Gomuks shared library $libFileName (${targetOS.name}/${targetArch.name}) to ${libFile.path}...",
    );
    final result = await Process.run(
      "go",
      ["build", "-tags", tags, "-o", libFile.path, "-buildmode=c-shared"],
      workingDirectory: gomuksBuildDir.resolve("pkg/ffi/").toFilePath(),
      environment: {
        "CGO_ENABLED": "1",
        "GOARCH": switch (targetArch) {
          Architecture.arm64 => "arm64",
          Architecture.arm => "arm",
          Architecture.x64 => "amd64",
          Architecture.ia32 => "386",
          _ => throw UnsupportedError("Unsupported architecture: $targetArch"),
        },
        ...extraEnv,
      },
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
