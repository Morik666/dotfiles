{ pkgs, inputs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.comic-shanns-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
    bluez
    stow
    # zsh
    fish
    zoxide
    python3

    git
    zip
    gzip
    unzip
    wget
    htop
    socat
    # neofetch
    fastfetch
    starship
    herdr
    inputs.nixpkgs-codex.legacyPackages.${pkgs.system}.codex

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

    hyprpaper #wall paper
    # eww #widgets

    dunst # notification daemon
    libnotify # dunst dependency

    #hyprlauncher  #app louncher
    wofi
    quickshell

    discord

    gtk-engine-murrine
    refine

    #gparted
    gnome-disk-utility
    file-roller
    pavucontrol
    pulseaudioFull
  ];
}
