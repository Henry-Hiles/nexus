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
          pkgs,
          system,
          ...
        }:

        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config = {
              android_sdk.accept_license = true;
              allowUnfree = true;
            };
          };

          devShells.default =
            let
              android = pkgs.callPackage ./nix/android.nix { };
            in
            pkgs.mkShell {
              packages = with pkgs; [
                jdk17
                cargo
                (flutter.override { extraPkgConfigPackages = [ pkgs.libsecret ]; })

                android.platform-tools
                (pkgs.writeShellScriptBin "rustup" (builtins.readFile ./nix/fake-rustup.sh))
              ];

              env = rec {
                LD_LIBRARY_PATH = "${
                  pkgs.lib.makeLibraryPath ([
                    pkgs.sqlite
                  ])
                }:./build/linux/x64/debug/plugins/flutter_vodozemac";

                ANDROID_HOME = "${android.androidsdk}/libexec/android-sdk";
                ANDROID_SDK_ROOT = ANDROID_HOME;
                JAVA_HOME = pkgs.jdk17;

                TOOLS = "${ANDROID_HOME}/build-tools/${"36.0.0"}";
                GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${TOOLS}/aapt2";
              };
            };
        };
    };
}
