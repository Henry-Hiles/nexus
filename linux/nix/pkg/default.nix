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
    emoji_text_field = "sha256-3TOys09EP2GRo6pUBGPXaqBlE39O2Cmwt42Hs1cTDKo=";
    linkify = "sha256-TpMD6+0zyY6i9l+6d8ErnVufmepCv362rCtnbOht/z4=";
    navigation_rail_m3e = "sha256-+2awDTQnK58gGRY1nuHckG/jjxarsYSRu9ovR4i4TEc=";
    unifiedpush_linux = "sha256-aIF/8oabSuuZo7K6qr4r7UBmf57qgoGAXyJ40fdntuQ=";
    unifiedpush_platform_interface = "sha256-aIF/8oabSuuZo7K6qr4r7UBmf57qgoGAXyJ40fdntuQ=";
    xdg_desktop_portal = "sha256-S6AHWHg1TDT4RoBm6S5E9D1yWy7nYnuqzPTy735M6Xw=";
  };

  postInstall = ''
    install -D assets/bundled/icon.svg $out/share/icons/hicolor/scalable/apps/nexus.svg
    install -Dm755 linux/nexus.federated.nexus.desktop -t $out/share/applications
    install -Dm644 linux/*.service -t $out/share/dbus-1/services
    wrapProgram $out/bin/nexus \
      --suffix LD_LIBRARY_PATH : $out/app/nexus/lib
  '';

  meta = {
    description = "A simple and user-friendly Matrix client";
    mainProgram = "nexus";
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ quadradical ];
  };
}
