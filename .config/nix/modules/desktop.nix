{ ... }:

{
  programs.hyprland.enable = true;
  programs.waybar.enable = true;
  # services.displayManager.cosmic-greeter.enable = true;
  # services.desktopManager.cosmic.enable = true;
  programs.steam.enable = true;
  services.blueman.enable = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  #xdg.portal.enable = true;
  #xdg.porta.extraPortals = [pkgs.xdg-desctop-portal-gtk ];

  environment.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      Hyprland
    fi
  '';
}
