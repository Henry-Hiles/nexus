{
  lib,
  callPackage,
  mpv-unwrapped,
  libass,
  libclang,
  flutter,
  stdenv,
  src,
  commit ? "dev",
}:

flutter.buildFlutterApplication {
  pname = "nexus";
  version = "1.0.0-alpha4";
  inherit src;

  preBuild = ''
    cp ${callPackage ./gomuks.nix { inherit src; }}/lib/* .
    packageRunCustom nexus generate source/scripts test
    packageRun build_runner build
  '';

  flutterBuildFlags = [
    "--dart-define=GIT_COMMIT=${commit}"
  ];

  buildInputs = [
    mpv-unwrapped
    libass
  ];

  env.LIBCLANG_PATH = lib.makeLibraryPath [ libclang ];

  autoPubspecLock = src + "/pubspec.lock";

  customSourceBuilders.avif_native = callPackage ./avif_native.nix { };

  gitHashes = {
    linkify = "sha256-TpMD6+0zyY6i9l+6d8ErnVufmepCv362rCtnbOht/z4=";
    fab_m3e = "sha256-5V9m6yY0jimx2gh7lQHYg4HDKQ4Wrl0ATmBhw5DkQMI=";
    m3e_design = "sha256-5V9m6yY0jimx2gh7lQHYg4HDKQ4Wrl0ATmBhw5DkQMI=";
    navigation_rail_m3e = "sha256-5V9m6yY0jimx2gh7lQHYg4HDKQ4Wrl0ATmBhw5DkQMI=";
    unifiedpush_linux = "sha256-aIF/8oabSuuZo7K6qr4r7UBmf57qgoGAXyJ40fdntuQ=";
    unifiedpush_platform_interface = "sha256-aIF/8oabSuuZo7K6qr4r7UBmf57qgoGAXyJ40fdntuQ=";
    webcrypto = "sha256-jC5hTIcfnhqm/rD9myrfXfA5+Wkf5CfTYjtAnlT4FN4=";
    xdg_desktop_portal = "sha256-8GgiXHGv+wy6hJgj/rZxbymMitNVmdDLAnedZm9STSc=";
  };

  postInstall = ''
    install -D assets/bundled/icon.svg $out/share/icons/hicolor/scalable/apps/nexus.svg
    install -Dm755 linux/*.desktop -t $out/share/applications
    install -Dm644 linux/*.service -t $out/share/dbus-1/services
    wrapProgram $out/bin/nexus \
      --suffix LD_LIBRARY_PATH : $out/app/nexus/lib
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
