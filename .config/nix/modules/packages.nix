{ pkgs, inputs, ... }:

let
  quickshellWithQtDeps = pkgs.symlinkJoin {
    name = "quickshell-with-qt-deps";
    paths = [ pkgs.quickshell ];
    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.qt6.wrapQtAppsHook
    ];
    buildInputs = with pkgs; [
      gsettings-desktop-schemas
      kdePackages.kdialog
      kdePackages.kirigami
      kdePackages.syntax-highlighting
      qt6.qt5compat
      qt6.qtimageformats
      qt6.qtmultimedia
      qt6.qtpositioning
      qt6.qtquicktimeline
      qt6.qtsensors
      qt6.qtsvg
      qt6.qttools
      qt6.qtvirtualkeyboard
      qt6.qtwayland
    ];
    postBuild = ''
      wrapQtApp "$out/bin/quickshell" \
        --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      wrapQtApp "$out/bin/qs" \
        --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    '';
  };
in
{
  services.upower.enable = true;

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

    hyprpaper #wall paper
    # eww #widgets

    dunst # notification daemon
    libnotify # dunst dependency

    #hyprlauncher  #app louncher
    wofi
    quickshellWithQtDeps

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
