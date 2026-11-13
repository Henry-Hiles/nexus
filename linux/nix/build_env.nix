{ pkgs, lib }:
# What building Nexus needs, shared by the dev shell and the e2e tests
{
  packages =
    with pkgs;
    [
      stdenv.cc
      # webcrypto's build hook runs CMake with the Unix Makefiles generator
      gnumake
      go
      git
      ffmpeg-headless

      libGL
      (flutter.override {
        # audioplayers plays audio through GStreamer
        extraPkgConfigPackages = [
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
        ];
      })
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      wayland
      (callPackage ./pkg/hook_pkg_config.nix { })
    ];

  env = lib.optionalAttrs pkgs.stdenv.isLinux {
    # nativeapi includes XInput2.h and GTK's Wayland headers, which need these, but xi.pc and gdk-3.0.pc
    # only list them privately, so its hook's pkg-config doesn't return them. Hooks only get NIX_ variables.
    "NIX_CFLAGS_COMPILE_${pkgs.stdenv.cc.suffixSalt}" =
      lib.concatMapStringsSep " " (pkg: "-isystem ${lib.getDev pkg}/include")
        (
          with pkgs;
          [
            libxext
            libxfixes
            wayland
          ]
        );
    # better_player loads libmpv at runtime to play videos
    LD_LIBRARY_PATH = "./build/native_assets/linux:${
      lib.makeLibraryPath [
        pkgs.zlib
        pkgs.mpv-unwrapped
      ]
    }";
    # audioplayers links GStreamer by name only, without its library directory
    LIBRARY_PATH = lib.makeLibraryPath [
      pkgs.gst_all_1.gstreamer
      pkgs.gst_all_1.gst-plugins-base
      pkgs.glib
    ];
    GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
      with pkgs.gst_all_1;
      [
        gstreamer
        gst-plugins-base
        gst-plugins-good
        gst-libav
      ]
    );
  };
}
