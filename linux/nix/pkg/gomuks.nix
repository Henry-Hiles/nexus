{
  src,
  buildGoModule,
}:

buildGoModule (finalAttrs: {
  pname = "gomuks-ffi";
  version = "submodule";

  doCheck = false;

  src = "${src}/gomuks";

  vendorHash = "sha256-EeGuh73jcK2aKmEJsMaAqQRJMzzHj3s8LrLb/QmorbQ=";

  buildPhase = ''
    runHook preBuild

    go build -buildmode=c-shared -o libgomuks.so -tags goolm,noheic ./pkg/ffi 

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm0644 libgomuks.so -t $out/lib

    runHook postInstall
  '';
})
