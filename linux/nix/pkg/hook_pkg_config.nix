{
  stdenvNoCC,
  pkg-config,
  pkg-config-unwrapped,
  makeWrapper,
  gtk3,
  libx11,
  libxi,
}:

# Build hooks run with a filtered environment that drops PKG_CONFIG_PATH, so
# nativeapi's hook can only find its libraries through a pkg-config on PATH.
stdenvNoCC.mkDerivation {
  name = "hook-pkg-config";
  dontUnpack = true;

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    gtk3
    libx11
    libxi
  ];

  installPhase = ''
    makeWrapper ${pkg-config-unwrapped}/bin/pkg-config $out/bin/pkg-config \
      --prefix PKG_CONFIG_PATH : "$PKG_CONFIG_PATH"
  '';
}
