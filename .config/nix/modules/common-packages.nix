{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    stow
    zoxide
    (python3.withPackages (pythonPackages: with pythonPackages; [
      requests
    ]))

    git
    zip
    gzip
    unzip
    unrar
    wget
    htop
    socat # Relay data between network sockets, files and serial ports.
    ripgrep
    # neofetch
    fastfetch
    starship
    dig # Query DNS records to troubleshoot domain name resolution.
    
    zellij
    lazygit
    vim
    helix
    lua-language-server
    stylua
    ruff # Python linter and formatter for checking and cleaning up code.
    yazi
    superfile
    (callPackage ../packages/mantix.nix { })
  ];
}
