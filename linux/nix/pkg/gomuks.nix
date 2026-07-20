{
  src,
  buildGoModule,
}:

buildGoModule (finalAttrs: {
  pname = "gomuks-ffi";
  version = "submodule";

  doCheck = false;

  src = "${src}/gomuks";

  vendorHash = "sha256-mNZEHOGByVqK1kSLC/Cf1VEvkDxRen+TmoV5CXvGrZ4=";

  buildPhase = ''
    runHook preBuild

    go build -buildmode=c-shared -o libgomuks.so -tags goolm,noheic,sqlite_fts5 ./pkg/ffi 

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm0644 libgomuks.so -t $out/lib

    runHook postInstall
  '';
})
