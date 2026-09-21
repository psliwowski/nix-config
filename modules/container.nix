{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.container.machine;
  machineSettings = lib.filterAttrs (_: value: value != null) {
    cpus = cfg.cpu;
    inherit (cfg) memory;
    disk_size = cfg.disk;
  };
in
{
  options.container.machine = {
    cpu = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      description = "Default CPU count for new Podman machines.";
    };
    memory = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      description = "Default memory in MiB for new Podman machines.";
    };
    disk = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      description = "Default disk capacity in GiB for new Podman machines.";
    };
  };

  config = {
    xdg.configFile."just/podman.just" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = ./just/podman.just;
    };

    home.packages = with pkgs; [
      podman
      docker-compose
    ];

    xdg.configFile."containers/containers.conf.d/50-machine.conf" = lib.mkIf (machineSettings != { }) {
      source = (pkgs.formats.toml { }).generate "podman-machine.conf" {
        machine = machineSettings;
      };
    };
  };
}
