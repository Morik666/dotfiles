{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/ando-system.nix
    ../../modules/ando-ssh.nix
    ../../modules/ando-desktop.nix
    ../../modules/ando-packages.nix
  ];

  # Keep the old Pop!_OS partition available after boot. Prefer a
  # /dev/disk/by-uuid/... path here once its UUID has been confirmed.
  fileSystems."/home/jarves/pop" = {
    device = "/dev/nvme0n1p3";
    fsType = "auto";
    options = [ "nofail" ];
  };
}
