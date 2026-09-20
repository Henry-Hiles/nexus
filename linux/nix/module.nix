self:
{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    mkEnableOption
    mkPackageOption
    types
    ;

  cfg = config.programs.nexus;
in
{
  options.programs.nexus = {
    enable = mkEnableOption "Nexus, a simple and user-friendly Matrix client";
    package = mkPackageOption self.packages.${pkgs.stdenv.hostPlatform.system} "nexus" { };

    enableNotifications = mkOption {
      description = ''
        Whether to enable push notifications support via UnifiedPush, installing
        {manpage}`kunifiedpush` and registering its systemd and D-Bus units.
      '';
      type = types.bool;
      default = false;
      example = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [ cfg.package ];
    }
    (mkIf cfg.enableNotifications {
      environment.systemPackages = [
        pkgs.kdePackages.kunifiedpush
      ];

      systemd.packages = [
        pkgs.kdePackages.kunifiedpush
      ];

      services.dbus.packages = [
        cfg.package
      ];
    })
  ]);
}
