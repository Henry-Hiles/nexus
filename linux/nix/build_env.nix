{ pkgs, lib }:
# What building Nexus needs, shared by the dev shell and the e2e tests
{
  packages =
    with pkgs;
    [
      stdenv.cc
      go
      git

      libGL
      (flutter.override {
        extraPkgConfigPackages = [
          mpv-unwrapped
          libass
        ];
      })
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      wayland
      # nativeapi includes XInput2.h, which needs these, but xi.pc only lists them privately
      libxext
      libxfixes
      (callPackage ./pkg/hook_pkg_config.nix { })
    ];

  env = lib.optionalAttrs pkgs.stdenv.isLinux {
    LD_LIBRARY_PATH = "./build/native_assets/linux:${lib.makeLibraryPath [ pkgs.zlib ]}";
  };
}
