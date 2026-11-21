{
  src,
  stdenv,
  buildGoModule,
}:

buildGoModule (
  finalAttrs:
  let
    filename = "libgomuks${stdenv.hostPlatform.extensions.sharedLibrary}";
  in
  {
    pname = "gomuks-ffi";
    version = "submodule";

    doCheck = false;

    src = "${src}/gomuks";

    vendorHash = "sha256-MJu9qN1NhUkjF3MAz+ejVMY9dxg8yxMBqCCHzPh9RHc=";

    buildPhase = ''
      runHook preBuild

      go build -buildmode=c-shared -o ${filename} -tags noheic,sqlite_fts5 ./pkg/ffi 

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      install -Dm0644 ${filename} -t $out/lib

      runHook postInstall
    '';
  }
)
