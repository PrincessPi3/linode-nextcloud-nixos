{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs:
    with inputs; let
      # supportedSystems = ["x86_64-linux" "x86-linux"];
      defaultSystem = "x86_64-linux";
      specialArgs = {inherit self inputs;};
      nixos-lib = import (nixpkgs + "/nixos/lib") { };
      pkgs = import nixpkgs {
        system = defaultSystem;
        config.allowUnfree = true;
      };
      # lib = nixpkgs.lib;
      # forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      sharedModules = [
        agenix.nixosModules.default
      ];
      mkNixos = system: systemModules: config:
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules =
            sharedModules
            ++ systemModules
            ++ [
              config
            ];
        };
    in {
      nixosConfigurations = {
        nextcloud =
          mkNixos defaultSystem [
            nixos-generators.nixosModules.linode
          ]
          self.nixosModules.nextcloud;
      };
      nixosModules = {
        nextcloud = ./hosts/nextcloud;
      };
      checks.${defaultSystem}.default = nixos-lib.runTest (import ./tests/main.nix {inherit self inputs pkgs;});
      packages.x86_64-linux = {
        linode = nixos-generators.nixosGenerate {
          system = defaultSystem;
          modules = [
            # you can include your own nixos configuration here, i.e.
            agenix.nixosModules.default
            self.nixosModules.nextcloud
          ];
          format = "linode";
        };
      };
    };
}
