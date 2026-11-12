{
  lib,
  callPackage,
  mpv-unwrapped,
  gst_all_1,
  ffmpeg-headless,
  libxext,
  libxfixes,
  libclang,
  flutter,
  stdenv,
  runCommand,
  yq,
  src,
  commit ? "dev",
}:

let
  pubspec = lib.importJSON (
    runCommand "pubspec.json" { nativeBuildInputs = [ yq ]; } ''
      yq . ${src}/pubspec.yaml > $out
    ''
  );
in
flutter.buildFlutterApplication {
  pname = "nexus";
  version = lib.head (lib.splitString "+" pubspec.version);
  inherit src;

  preBuild = ''
    cp ${callPackage ./gomuks.nix { inherit src; }}/lib/* .
    packageRunCustom nexus generate source/scripts test
    packageRun build_runner build
  '';

  flutterBuildFlags = [
    "--dart-define=GIT_COMMIT=${commit}"
  ];

  nativeBuildInputs = [ (callPackage ./hook_pkg_config.nix { }) ];

  buildInputs = [
    # audioplayers plays audio through GStreamer
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    # nativeapi includes XInput2.h, which needs these, but xi.pc only lists them privately
    libxext
    libxfixes
  ];

  env.LIBCLANG_PATH = lib.makeLibraryPath [ libclang ];

  autoPubspecLock = src + "/pubspec.lock";

  customSourceBuilders.avif_native = callPackage ./avif_native.nix { };

  gitHashes = {
    linkify = "sha256-TpMD6+0zyY6i9l+6d8ErnVufmepCv362rCtnbOht/z4=";
    location = "sha256-zWnffXiK1LD4Ln23coPozBjYfTlhZmBhC5Z8mCdAgwQ=";
    fab_m3e = "sha256-5V9m6yY0jimx2gh7lQHYg4HDKQ4Wrl0ATmBhw5DkQMI=";
    fluttertagger = "sha256-tHUNU2+fBPkq5UK5YRi3SWs1zF2PIPz6RgSbwignU/I=";
    m3e_design = "sha256-5V9m6yY0jimx2gh7lQHYg4HDKQ4Wrl0ATmBhw5DkQMI=";
    native_toolchain_cmake = "sha256-/drnHZebmTnsCnHgC1xmlAe+U4PSrjw5Sm9axicuTrY=";
    navigation_rail_m3e = "sha256-5V9m6yY0jimx2gh7lQHYg4HDKQ4Wrl0ATmBhw5DkQMI=";
    unifiedpush_linux = "sha256-KQKyBPL2ORK9O89C4K3RHGve/lvFaU1vIjSDnj6+bj4=";
    unifiedpush_platform_interface = "sha256-KQKyBPL2ORK9O89C4K3RHGve/lvFaU1vIjSDnj6+bj4=";
    webcrypto = "sha256-YHyCMVmroxj047r6KLrk5gMbAGwZ5fZvCSOaX5p49uI=";
    xdg_desktop_portal = "sha256-8GgiXHGv+wy6hJgj/rZxbymMitNVmdDLAnedZm9STSc=";
  };

  postInstall = ''
    install -D assets/bundled/icon.svg $out/share/icons/hicolor/scalable/apps/nexus.svg
    install -Dm755 linux/*.desktop -t $out/share/applications
    install -Dm644 linux/*.service -t $out/share/dbus-1/services
    # better_player loads libmpv at runtime to play videos, and audioplayers
    # needs GStreamer's plugins to decode audio
    # gomuks uses ffmpeg and ffprobe for video thumbnails and metadata
    wrapProgram $out/bin/nexus \
      --suffix LD_LIBRARY_PATH : $out/app/nexus/lib \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ mpv-unwrapped ]} \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg-headless ]} \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : ${
        lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
          with gst_all_1;
          [
            gstreamer
            gst-plugins-base
            gst-plugins-good
            gst-libav
          ]
        )
      }
  '';

  meta = {
    description = "A simple and user-friendly Matrix client";
    mainProgram = "nexus";
    platforms = lib.platforms.unix;

    # https://github.com/NixOS/nixpkgs/blob/c59305bab2065cfecc4944690d9eedbb56f3a9fa/pkgs/development/compilers/flutter/build-support/build-flutter-application.nix#L15
    broken = stdenv.hostPlatform.isDarwin;

    maintainers = with lib.maintainers; [ quadradical ];
  };
}
