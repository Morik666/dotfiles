{
  description = "NixOS configurations for ando and bespin";

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-codex.url = "github:NixOS/nixpkgs/nixos-unstable";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

  };

  outputs = { self, nixpkgs, zen-browser, ... } @ inputs: {
    nixosConfigurations = {
      ando = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/ando
        ];
      };
      bespin = nixpkgs.lib.nixosSystem {
        # Change this if bespin uses ARM hardware.
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/bespin ];
      };
    };
  };
}
