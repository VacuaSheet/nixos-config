{       
  description = "Flake Mestre 2026: Dev + Games + Nixpak";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; # Estavel
    unstable.url = "github:nixos/nixpkgs/nixos-unstable"; # Instavel
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
     inputs.goanime.url = "github:alvarorichard/GoAnime";
  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak, microvm, nix-gaming, goanime, ... } @inputs: 
  let
    # DEFINA A VARIÁVEL AQUI (Isso resolve o erro de undefined variable)
    unstablePkgs = import inputs.unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
   in
 {
    nixosConfigurations.alligare = nixpkgs.lib.nixosSystem {
      # O inherit inputs permite que você use todos os inputs dentro do configuration.nix
      specialArgs = { inherit inputs; unstable = unstablePkgs;  };
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
          home-manager.backupFileExtension = "backup"; 
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
