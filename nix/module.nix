{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.tuxedo-control-center;

  tuxedo-control-center = pkgs.callPackage ./tuxedo-control-center {};
in
{
  options.hardware.tuxedo-control-center = {
    enable = mkEnableOption ''
      Tuxedo Control Center, the official fan and power management UI
      for Tuxedo laptops.

      This module does not offer any hardcoded configuration. So you
      will get the default configuration until you change it in the
      Tuxedo Control Center.
    '';

    package = mkOption {
      type = types.package;
      default = tuxedo-control-center;
      defaultText = "pkgs.tuxedo-control-center";
      description = ''
        Which package to use for tuxedo-control-center.
      '';
    };
  };

  config = mkIf cfg.enable {
    hardware.tuxedo-keyboard.enable = true;
    boot.kernelModules = [ "tuxedo_io" ];

    environment.systemPackages = [ cfg.package ];
    services.dbus.packages = [ cfg.package ];

    systemd.services.tccd = {
      path = [ cfg.package ];

      description = "Tuxedo Control Center Service";

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/tccd --start";
        ExecStop = "${cfg.package}/bin/tccd --stop";
      };
    };

    systemd.services.tccd-sleep = {
      path = [ cfg.package ];

      description = "Tuxedo Control Center Service (sleep/resume)";

      wantedBy = [ "sleep.target" ];

      unitConfig = {
        StopWhenUnneeded = "yes";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";

        ExecStart = "systemctl stop tccd";
        ExecStop = "systemctl start tccd";
      };
    };
  };
}