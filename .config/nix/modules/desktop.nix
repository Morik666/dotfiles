{ ... }:

{
  programs.hyprland.enable = true;
  # services.displayManager.cosmic-greeter.enable = true;
  # services.desktopManager.cosmic.enable = true;
  programs.steam.enable = true;
  services.blueman.enable = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

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
    if [ "$(tty)" = "/dev/tty1" ]; then
      Hyprland
    fi
  '';
}
