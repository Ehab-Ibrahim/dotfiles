{inputs, ...}: {
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    ./catppuccin.nix
    ./cosmic-de.nix
  ];
}
