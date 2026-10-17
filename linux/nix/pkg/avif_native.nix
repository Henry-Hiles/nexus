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
      sha256 = "252b064f8ff4f0f265bc44294d4a7ed703dd7199688942c272dd8aa8d3039d5a";
    };
    aarch64-linux = {
      arch = "arm64";
      sha256 = "cdcf17cfd18b9b0f965b72615ddf11246121114577dc570d0bba25964e56c726";
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
    url = "https://github.com/Zhangw1998/avif_native/releases/download/native-v0.1.0/${key}-libavif_native.so.gz";
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
