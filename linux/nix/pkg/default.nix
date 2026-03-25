{
  lib,
  callPackage,
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

  env.LIBCLANG_PATH = lib.makeLibraryPath [ libclang ];

  autoPubspecLock = src + "/pubspec.lock";

  gitHashes = {
    window_size = "sha256-XelNtp7tpZ91QCEcvewVphNUtgQX7xrp5QP0oFo6DgM=";
    flutter_chat_ui = "sha256-4fuag7lRH5cMBFD3fUzj2K541JwXLoz8HF/4OMr3uhk=";
    flutter_link_previewer = "sha256-4fuag7lRH5cMBFD3fUzj2K541JwXLoz8HF/4OMr3uhk=";
  };

  meta = {
    description = "A simple and user-friendly Matrix client";
    mainProgram = "nexus";
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ quadradical ];
  };
}
