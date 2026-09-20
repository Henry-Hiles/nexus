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
    mkEnableOption
    mkPackageOption
    ;

  cfg = config.programs.nexus;
in
{
  options.programs.nexus = {
    enable = mkEnableOption "Nexus, a simple and user-friendly Matrix client";
    package = mkPackageOption self.packages.${pkgs.stdenv.hostPlatform.system} "default" { };

    enableNotifications = mkEnableOption "notifications support via UnifiedPush";
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
