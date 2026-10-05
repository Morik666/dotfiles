{ pkgs, inputs, ... }:

{
  services.upower.enable = true; # Report battery levels and power status to desktop apps.
  services.power-profiles-daemon.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.comic-shanns-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl # Control media players from scripts or keybindings (play, pause, skip).
    cliphist
    wl-clipboard
    flameshot
    ddcutil # Adjust external monitor brightness and settings over DDC/CI.
    bluez # Bluetooth tools, including bluetoothctl for pairing and managing devices.
    inputs.nixpkgs-codex.legacyPackages.${pkgs.stdenv.hostPlatform.system}.codex
    # kitty
    ghostty
    remmina
    filezilla

    firefox
    inputs.zen-browser.packages.x86_64-linux.default
    # .override {
    #   policies = {
    #       DisableAppUpdate = true;
    #       DisableTelemetry = true;
    #   };
    # }

    nemo
    kdePackages.ark # KDE graphical archive manager for creating and extracting archives.
    kdePackages.dolphin
    kdePackages.breeze-icons
    kdePackages.gwenview
    kdePackages.okular # KDE document viewer for PDFs, ebooks and other formats.
    libreoffice-qt-stable
    mpv # Audio and video player with command-line controls.
    simple-scan
    # geeqie

    adw-gtk3
    glib
    nwg-look # Graphical settings for GTK themes, icons, fonts and cursors.

    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    # Disabled until Hyprspace supports Hyprland 0.56.
    # hyprlandPlugins.hyprspace

    # eww #widgets

    #hyprlauncher  #app louncher

    (discord.override {
      commandLineArgs = "--ozone-platform=wayland";
    })
    telegram-desktop
    protonmail-desktop
    whatsie
    vesktop # Alternative Discord desktop client with Vencord customization.

    #gparted
    gnome-disk-utility
    file-roller # GNOME graphical archive manager; overlaps with Ark.
    pavucontrol
    pulseaudioFull

    blockbench
    libresprite
  ];
}
