{ pkgs, lib }:
let
  android = pkgs.androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformToolsVersion = "37.0.1";
    buildToolsVersions = [
      "35.0.0"
      "36.0.0"
    ];
    cmakeVersions = [ "3.22.1" ];
    platformVersions = [
      "34"
      "35"
      "36"
      "37.0"
    ];
    abiVersions = [
      "armeabi-v7a"
      "arm64-v8a"
    ];
    includeNDK = true;
    ndkVersions = [ "28.2.13676358" ];
  };
  buildEnv = import ./build_env.nix { inherit pkgs lib; };
in
pkgs.mkShell {
  packages = buildEnv.packages ++ [ android.platform-tools ];

  env =
    rec {
      LIBCLANG_PATH = lib.makeLibraryPath [ pkgs.libclang ];

      ANDROID_HOME = "${android.androidsdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = ANDROID_HOME;
      JAVA_HOME = pkgs.jdk21;

      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/36.0.0/aapt2";
    }
    // buildEnv.env;
}
