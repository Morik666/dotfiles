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

  # Expose driverless USB scanners (AirScan/eSCL) to SANE.
  services.ipp-usb.enable = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    x-scheme-handler/http=zen-beta.desktop
    x-scheme-handler/https=zen-beta.desktop
    x-scheme-handler/mailto=proton-mail.desktop
    text/html=zen-beta.desktop
    application/xhtml+xml=zen-beta.desktop

    inode/directory=org.kde.dolphin.desktop

    application/pdf=org.kde.okular.desktop

    application/msword=libreoffice-writer.desktop
    application/rtf=libreoffice-writer.desktop
    application/vnd.ms-word=libreoffice-writer.desktop
    application/vnd.oasis.opendocument.text=libreoffice-writer.desktop
    application/vnd.oasis.opendocument.text-template=libreoffice-writer.desktop
    application/vnd.openxmlformats-officedocument.wordprocessingml.document=libreoffice-writer.desktop
    application/vnd.openxmlformats-officedocument.wordprocessingml.template=libreoffice-writer.desktop
    text/rtf=libreoffice-writer.desktop

    application/vnd.ms-excel=libreoffice-calc.desktop
    application/vnd.oasis.opendocument.spreadsheet=libreoffice-calc.desktop
    application/vnd.oasis.opendocument.spreadsheet-template=libreoffice-calc.desktop
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet=libreoffice-calc.desktop
    application/vnd.openxmlformats-officedocument.spreadsheetml.template=libreoffice-calc.desktop
    text/csv=libreoffice-calc.desktop

    application/vnd.ms-powerpoint=libreoffice-impress.desktop
    application/vnd.oasis.opendocument.presentation=libreoffice-impress.desktop
    application/vnd.oasis.opendocument.presentation-template=libreoffice-impress.desktop
    application/vnd.openxmlformats-officedocument.presentationml.presentation=libreoffice-impress.desktop
    application/vnd.openxmlformats-officedocument.presentationml.slideshow=libreoffice-impress.desktop
    application/vnd.openxmlformats-officedocument.presentationml.template=libreoffice-impress.desktop

    application/vnd.oasis.opendocument.graphics=libreoffice-draw.desktop
    application/vnd.oasis.opendocument.graphics-template=libreoffice-draw.desktop

    image/avif=org.kde.gwenview.desktop
    image/bmp=org.kde.gwenview.desktop
    image/gif=org.kde.gwenview.desktop
    image/heif=org.kde.gwenview.desktop
    image/jpeg=org.kde.gwenview.desktop
    image/jxl=org.kde.gwenview.desktop
    image/openraster=org.kde.gwenview.desktop
    image/png=org.kde.gwenview.desktop
    image/svg+xml=org.kde.gwenview.desktop
    image/tiff=org.kde.gwenview.desktop
    image/webp=org.kde.gwenview.desktop
    image/x-icns=org.kde.gwenview.desktop
    image/x-ico=org.kde.gwenview.desktop
    image/x-psd=org.kde.gwenview.desktop
    image/x-tga=org.kde.gwenview.desktop
    image/x-xcf=org.kde.gwenview.desktop

    video/3gp=mpv.desktop
    video/3gpp=mpv.desktop
    video/3gpp2=mpv.desktop
    video/mp2t=mpv.desktop
    video/mp4=mpv.desktop
    video/mpeg=mpv.desktop
    video/ogg=mpv.desktop
    video/quicktime=mpv.desktop
    video/vnd.avi=mpv.desktop
    video/webm=mpv.desktop
    video/x-flv=mpv.desktop
    video/x-m4v=mpv.desktop
    video/x-matroska=mpv.desktop
    video/x-msvideo=mpv.desktop
    video/x-ms-wmv=mpv.desktop
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
