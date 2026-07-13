{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };
  programs.fish.enable = true;
  programs.steam.enable = true;
  # services.displayManager.cosmic-greeter.enable = true;
  # services.desktopManager.cosmic.enable = true;
  services.blueman.enable = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.hplipWithPlugin ];
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    x-scheme-handler/http=zen-beta.desktop
    x-scheme-handler/https=zen-beta.desktop
    text/html=zen-beta.desktop
    application/xhtml+xml=zen-beta.desktop
  '';

  #xdg.portal.enable = true;
  #xdg.porta.extraPortals = [pkgs.xdg-desctop-portal-gtk ];

  environment.loginShellInit = ''
    if [ "''${XDG_VTNR:-}" = "1" ] \
      && [ -z "''${WAYLAND_DISPLAY:-}" ] \
      && [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      exec start-hyprland
    fi
  '';
}
