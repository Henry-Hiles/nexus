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
          };
        in
        {
          inherit default;

          flatpak = inputs.nix2flatpak.lib.${system}.mkFlatpak {
            appName = "Nexus";
            developer = "QuadRadical";
            appId = "nexus.federated.nexus";
            package = default;
            runtime = "org.gnome.Platform/49";
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
    };

  flake.nixosModules.default = import ./module.nix self;
}
