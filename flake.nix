{       
  description = "Flake Mestre 2026: Dev + Games + Nixpak";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };	
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    microvm.url = "github:astro/microvm.nix";
    nix-gaming.url = "github:fufexan/nix-gaming";
  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak, microvm, nix-gaming, nixpkgs-unstable, ... } @inputs: {
    nixosConfigurations.alligare = nixpkgs.lib.nixosSystem {
      # O inherit inputs permite que você use todos os inputs dentro do configuration.nix
      specialArgs = { inherit inputs; };
      modules = [

        # 1. ADICIONE ESTA LINHA ABAIXO PARA DEFINIR A PLATAFORMA
        { nixpkgs.hostPlatform = "x86_64-linux"; } 

        ./configuration.nix
        ./flatpak.nix
        nix-flatpak.nixosModules.nix-flatpak
        microvm.nixosModules.host
        home-manager.nixosModules.home-manager
        {	
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users."_-_-yakov_-_-" = {
            imports = [
              ./home.nix
              inputs.plasma-manager.homeModules.plasma-manager
            ];
          };
        }
      ];
    };
  };
}
