{ self, inputs, ... }: {

  perSystem =
    {
      pkgs,
      system,
      lib,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };

      packages =
        let
          default = pkgs.callPackage ./pkg {
            src = self;
            commit = self.shortRev or self.dirtyShortRev;
          };
        in
        {
          inherit default;

          flatpak = inputs.nix2flatpak.lib.${system}.mkFlatpak {
            appName = "Nexus";
            developer = "QuadRadical";
            appId = "nexus.federated.nexus";
            # The runtime's GStreamer gets loaded instead of ours, and it can't
            # load our plugins, so keep wrapGAppsHook from pointing it at them
            package = default.overrideAttrs (old: {
              postInstall = ''
                unset GST_PLUGIN_SYSTEM_PATH_1_0
              ''
              + old.postInstall;
            });
            runtime = "org.gnome.Platform/51";
            permissions = {
              share = [ "network" ];
              sockets = [
                "pulseaudio"
                "fallback-x11"
                "wayland"
              ];

              talk-names = [
                "org.unifiedpush.Distributor.*"
                "org.freedesktop.Notifications"
              ];
              devices = [ "dri" ];
            };
          };

          gomuks = pkgs.callPackage ./pkg/gomuks.nix {
            src = self;
          };
        };

      devShells.default = pkgs.callPackage ./devshell.nix { };

      apps =
        let
          buildEnv = import ./build_env.nix { inherit pkgs lib; };
          e2e = pkgs.writeShellApplication {
            name = "nexus-e2e";
            runtimeInputs =
              buildEnv.packages
              ++ (with pkgs; [
                # TEMPORARY: matrix-continuwuity, once the local fixes are released
                (inputs.continuwuity.packages.${system}.default.overrideAttrs { doCheck = false; })
                curl
                dbus
              ]);
            runtimeEnv = buildEnv.env;
            text = builtins.readFile ./e2e.sh;
          };
          screenshots = pkgs.writeShellApplication {
            name = "nexus-screenshots";
            runtimeInputs =
              buildEnv.packages
              ++ (with pkgs; [
                dbus
                oxipng
                pngquant
              ]);
            runtimeEnv = buildEnv.env;
            text = builtins.readFile ./screenshots.sh;
          };

          headless =
            program:
            lib.getExe (
              pkgs.writeShellApplication {
                name = "${lib.getName program}-headless";
                runtimeInputs = [ pkgs.cage ];
                runtimeEnv = {
                  WLR_BACKENDS = "headless";
                  __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
                };
                text = ''
                  unset DISPLAY WAYLAND_DISPLAY
                  # Wayland needs one, which CI may not have
                  XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-$(mktemp -d)}"
                  export XDG_RUNTIME_DIR

                  exec cage -- ${lib.getExe program} "$@"
                '';
              }
            );
        in
        {
          e2e = {
            type = "app";
            program = lib.getExe e2e;
          };

          bump-libmpv = {
            type = "app";
            program = lib.getExe (
              pkgs.writeShellApplication {
                name = "nexus-bump-libmpv";
                runtimeInputs = with pkgs; [
                  coreutils
                  curl
                  git
                  gnugrep
                  gnused
                  jq
                ];
                text = builtins.readFile ./bump_libmpv.sh;
              }
            );
          };

          e2e-headless = {
            type = "app";
            program = headless e2e;
          };

          screenshots = {
            type = "app";
            program = headless screenshots;
          };
        };
    };

  flake.nixosModules.default = import ./module.nix self;
}
