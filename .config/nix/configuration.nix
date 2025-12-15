{ config, pkgs, system, inputs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      # allowUnfreePredicate = pkg: builtins.elem (builtins.parseDrvName pkg.name).name ["steam"];
    };
  };
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ando"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.networkmanager.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };


  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "uk_UA.UTF-8";
    LC_IDENTIFICATION = "uk_UA.UTF-8";
    LC_MEASUREMENT = "uk_UA.UTF-8";
    LC_MONETARY = "uk_UA.UTF-8";
    LC_NAME = "uk_UA.UTF-8";
    LC_NUMERIC = "uk_UA.UTF-8";
    LC_PAPER = "uk_UA.UTF-8";
    LC_TELEPHONE = "uk_UA.UTF-8";
    LC_TIME = "uk_UA.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
  };
  # services.xserver.xkb = {
  #   layout = "us,ua";
  #   variant = ",homophonic";
  #   options = "grp:win_space_toggle";
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jarves = {
    isNormalUser = true;
    description = "jarves";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "jarves";

  fonts.packages = with pkgs; [
    nerd-fonts.comic-shanns-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
    bluez
    git
    zip
    gzip
    unzip
    wget
    htop
    neofetch
    starship

    vim
    helix
    yazi
    kitty
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

    discord

    gtk-engine-murrine
    refine

    #gparted
    gnome-disk-utility
    file-roller
    pavucontrol
    pulseaudioFull
  ];
  
  programs.hyprland.enable = true;
  programs.waybar.enable = true;
  programs.steam.enable = true;
  services.blueman.enable = true;

  #xdg.portal.enable = true;
  #xdg.porta.extraPortals = [pkgs.xdg-desctop-portal-gtk ];
  
  environment.loginShellInit = ''
    nmcli device wifi connect "Mutabor_upstairs" --ask &
    if [ "$(tty)" = "/dev/tty1" ]; then
      Hyprland
    fi
  '';

  system.stateVersion = "25.05"; # Do not change

}
