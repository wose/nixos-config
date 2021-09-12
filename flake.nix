{
  description = "NixOS System Configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, mailserver, nixpkgs }: {
    nixosConfigurations = {
      beholder = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          mailserver.nixosModules.mailserver
          ./hosts/beholder/configuration.nix
        ];
      };
    };
  };

}
