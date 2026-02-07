{
  description = "Nexus Flutter Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {
      flake-parts,
      nixpkgs,
      self,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          lib,
          pkgs,
          system,
          ...
        }:

        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config = {
              permittedInsecurePackages = [ "olm-3.2.16" ];
              android_sdk.accept_license = true;
              allowUnfree = true;
            };
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              go
              olm
              git
              llvm
              clang
              flutter
            ];

            env = {
              LIBCLANG_PATH = lib.makeLibraryPath [ pkgs.libclang ];
              LD_LIBRARY_PATH = lib.makeLibraryPath [
                pkgs.zlib
                "./build/native_assets/linux"
              ];
              CPATH = lib.makeSearchPath "include" [ pkgs.glibc.dev ];
            };
          };
        };
    };
}
