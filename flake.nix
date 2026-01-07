{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Secrets
    secrets.url = "git+ssh://git@github.com/Ehab-Ibrahim/secrets.git";

    # Nix GL
    nixgl.url = "github:nix-community/nixGL";
    nixgl.inputs.nixpkgs.follows = "nixpkgs";

    # Catppuccin
    catppuccin.url = "github:catppuccin/nix";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Helper function to make a home-manager config
    mkHome = {
      system ? "x86_64-linux",
      username ? "eibrahim",
      use-nixgl ? true,
    }: let
      vars = {inherit system username use-nixgl;};
      secrets = inputs.secrets;
    in
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs outputs secrets vars;};
        modules = [
          inputs.catppuccin.homeModules.catppuccin
          ./home-manager/home.nix
        ];
      };
  in {
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        # > Our main nixos configuration file <
        modules = [./nixos/configuration.nix];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "eibrahim@nixos" = mkHome {use-nixgl = false;};
      "eibrahim@popos" = mkHome {};
    };
  };
}
