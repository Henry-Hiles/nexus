{
  lib,
  callPackage,
  mpv-unwrapped,
  libass,
  libclang,
  flutter,
  src,
}:

flutter.buildFlutterApplication {
  pname = "nexus";
  version = "0.1.0";
  inherit src;

  preBuild = ''
    cp ${callPackage ./gomuks.nix { inherit src; }}/lib/* .
    packageRunCustom nexus generate source/scripts test
    packageRun build_runner build
  '';

  buildInputs = [
    mpv-unwrapped
    libass
  ];

  env.LIBCLANG_PATH = lib.makeLibraryPath [ libclang ];

  autoPubspecLock = src + "/pubspec.lock";

  gitHashes = {
    window_size = "sha256-XelNtp7tpZ91QCEcvewVphNUtgQX7xrp5QP0oFo6DgM=";
    dynamic_system_colors = "sha256-GInPqU7r4Kj7+CNBQnf95u0BiagOUI6EtcW0A18pfd0=";
    emoji_text_field = "sha256-3TOys09EP2GRo6pUBGPXaqBlE39O2Cmwt42Hs1cTDKo=";
    linkify = "sha256-mxV/XHLxF9cn7sUPr2SUNjVmDr5lbxkuGCbNdyiZi2c=";
  };

  postInstall = ''
    install -D assets/icon.svg $out/share/icons/hicolor/scalable/apps/nexus.svg
    install -Dm755 linux/nexus.federated.Nexus.desktop -t $out/share/applications
      wrapProgram $out/bin/nexus \
      --suffix LD_LIBRARY_PATH : $out/app/nexus/lib
  '';

  meta = {
    description = "A simple and user-friendly Matrix client";
    mainProgram = "nexus";
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ quadradical ];
  };
}
