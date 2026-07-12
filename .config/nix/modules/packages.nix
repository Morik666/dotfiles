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
    ddcutil
    bluez
    stow
    zoxide
    python3

    git
    zip
    gzip
    unzip
    wget
    htop
    socat
    ripgrep
    # neofetch
    fastfetch
    starship
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

    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default

    # eww #widgets

    #hyprlauncher  #app louncher

    discord

    #gparted
    gnome-disk-utility
    file-roller
    pavucontrol
    pulseaudioFull
  ];
}
