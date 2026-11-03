# avif_native's build hook downloads its prebuilt library, which the sandbox
# can't do, so bundle it and point the manifest at the local copy instead
{
  stdenv,
  fetchurl,
  jq,
}:
let
  artifacts = {
    x86_64-linux = {
      arch = "x64";
      sha256 = "fa36210bc95b70abd14c20fd626204f57d0ef947297e9ff8ee66855c01e2c17f";
    };
    aarch64-linux = {
      arch = "arm64";
      sha256 = "163487e98b5eee0676be0dc8d3f60b5e0e5b67191a8a0a2abb5c8fad14a3a506";
    };
  };
  inherit (artifacts.${stdenv.hostPlatform.system}) arch sha256;
  key = "linux-${arch}-decode-dav1d";
in
{ version, src, ... }:
stdenv.mkDerivation {
  pname = "avif_native";
  inherit version src;
  inherit (src) passthru;

  nativeBuildInputs = [ jq ];

  library = fetchurl {
    url = "https://github.com/Zhangw1998/avif_native/releases/download/native-v0.2.0/${key}-libavif_native.so.gz";
    inherit sha256;
  };

  # The hook checksums the library, so it must stay byte-identical
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    cp -r . $out
    chmod -R u+w $out
    gunzip -c $library > $out/native/libavif_native.so
    jq '.artifacts["${key}"].path = "libavif_native.so"' \
      native/manifest.json > $out/native/manifest.json

    runHook postInstall
  '';
}
