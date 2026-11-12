{ pkgs, lib }:
# What building Nexus needs, shared by the dev shell and the e2e tests
{
  packages =
    with pkgs;
    [
      stdenv.cc
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
      # nativeapi includes XInput2.h, which needs these, but xi.pc only lists them privately
      libxext
      libxfixes
      (callPackage ./pkg/hook_pkg_config.nix { })
    ];

  env = lib.optionalAttrs pkgs.stdenv.isLinux {
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
