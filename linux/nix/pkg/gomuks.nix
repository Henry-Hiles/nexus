{
  src,
  buildGoModule,
}:

buildGoModule (finalAttrs: {
  pname = "gomuks-ffi";
  version = "submodule";

  doCheck = false;

  src = "${src}/gomuks";

  vendorHash = "sha256-4QU51WGiNKYm7z/ajnas2qQaMK5BgyHwPfmNpQvW0qg=";

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
