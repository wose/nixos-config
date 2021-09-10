{
  description = "NixOS System Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      beholder = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/beholder/configuration.nix
        ];
      };
    };
  };

}
