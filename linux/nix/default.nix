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
            package = default;
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

      apps.e2e =
        let
          buildEnv = import ./build_env.nix { inherit pkgs lib; };
        in
        {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "nexus-e2e";
              runtimeInputs =
                buildEnv.packages
                ++ (with pkgs; [
                  # TEMPORARY: matrix-continuwuity, once the local fixes are released
                  inputs.continuwuity.packages.${system}.default
                  curl
                  dbus
                ]);
              runtimeEnv = buildEnv.env;
              text = builtins.readFile ./e2e.sh;
            }
          );
        };
    };

  flake.nixosModules.default = import ./module.nix self;
}
