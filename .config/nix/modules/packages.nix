{ pkgs, inputs, ... }:

{
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.comic-shanns-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
    cliphist
    flameshot
    ddcutil
    bluez
    stow
    zoxide
    python3

    git
    zip
    gzip
    unzip
    unrar
    wget
    htop
    socat
    ripgrep
    # neofetch
    fastfetch
    starship
    dig
    
    herdr
    inputs.nixpkgs-codex.legacyPackages.${pkgs.stdenv.hostPlatform.system}.codex
    lazygit
    vim
    helix
    yazi
    # kitty
    ghostty

    firefox
    inputs.zen-browser.packages.x86_64-linux.default
    # .override {
    #   policies = {
    #       DisableAppUpdate = true;
    #       DisableTelemetry = true;
    #   };
    # }

    nemo
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.breeze-icons
    kdePackages.gwenview
    kdePackages.okular
    libreoffice-qt6-fresh
    mpv
    simple-scan
    geeqie

    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    hyprlandPlugins.hyprspace

    # eww #widgets

    #hyprlauncher  #app louncher

    (discord.override {
      commandLineArgs = "--ozone-platform=wayland";
    })
    telegram-desktop
    protonmail-desktop
    whatsie
    vesktop

    #gparted
    gnome-disk-utility
    file-roller
    pavucontrol
    pulseaudioFull

    blockbench
    libresprite
  ];
}
