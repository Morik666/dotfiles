{ ... }:
{
  # Add bespin-only CLI packages with environment.systemPackages here.
  # Immich is a service: the NixOS module installs it and its dependencies.
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    mediaLocation = "/var/lib/immich";
  };
}
