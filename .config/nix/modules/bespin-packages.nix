{ config, lib, pkgs, ... }:
let
  storage = "/srv/bespin-storage";
  media = config.services.immich.mediaLocation;
  backupFile = "${config.services.postgresqlBackup.location}/all.sql.gz";
in
{
  fileSystems."${storage}" = {
    device = "/dev/disk/by-label/bespin-data";
    fsType = "btrfs";
    options = [
      "nofail"
      "x-systemd.device-timeout=15s"
      "x-systemd.before=systemd-tmpfiles-setup.service"
    ];
  };

  fileSystems."${media}" = {
    device = "${storage}/immich";
    fsType = "none";
    options = [
      "bind"
      "nofail"
      "x-systemd.requires-mounts-for=${storage}"
      "x-systemd.before=systemd-tmpfiles-setup.service"
    ];
  };

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ storage ];
  };

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = false;
    mediaLocation = "/var/lib/immich";
  };

  networking.firewall.extraCommands = ''
    iptables -w -A nixos-fw -s 192.168.1.0/24 -p tcp --dport ${toString config.services.immich.port} -j nixos-fw-accept
  '';

  systemd.services.immich-server.unitConfig = {
    RequiresMountsFor = [ storage media ];
    AssertPathIsMountPoint = [ storage media ];
  };

  # Leave CPU capacity for SSH during batch processing on this six-CPU host.
  systemd.slices."system-immich".sliceConfig.CPUQuota = "400%";

  services.postgresqlBackup = {
    enable = true;
    location = "${storage}/postgresql-backups";
    startAt = [ ];
  };

  systemd.services.postgresqlBackup = {
    after = [ "postgresql.target" ];
    # Prepare the destination after the storage mount is available.
    serviceConfig.ExecStartPre = "+${pkgs.coreutils}/bin/install -d -m 0700 -o postgres ${lib.escapeShellArg config.services.postgresqlBackup.location}";
    unitConfig = {
      RequiresMountsFor = storage;
      AssertPathIsMountPoint = storage;
    };
  };
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "bespin";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        if [[ $# == 0 || ( $# == 1 && ( "$1" == --help || "$1" == -h ) ) ]]; then
          printf 'Usage: bespin imich\nBack up the Immich database and offer to shut down.\n'
          exit 0
        fi
        if [[ $# != 1 || "$1" != imich ]]; then
          printf 'Usage: bespin imich\n' >&2
          exit 2
        fi

        printf 'Backing up PostgreSQL to the HDD mirror…\n'
        if ! sudo systemctl start postgresqlBackup.service; then
          printf 'Database backup failed. Check journalctl -u postgresqlBackup.service.\n' >&2
          exit 1
        fi
        if ! sudo ${lib.getExe pkgs.gzip} -t -- ${lib.escapeShellArg backupFile}; then
          printf 'The database dump failed the gzip integrity check.\n' >&2
          exit 1
        fi
        printf 'Database backup succeeded. Saved and checked %s.\n' ${lib.escapeShellArg backupFile}

        if [[ -t 0 ]] && read -r -p 'Shut down Bespin now? [y/N] ' answer; then
          case "$answer" in
            [yY]|[yY][eE][sS]) sudo systemctl poweroff ;;
          esac
        fi
      '';
    })
  ];
}
