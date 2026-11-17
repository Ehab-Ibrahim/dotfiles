{pkgs, ...}: {
  imports = [
    # Modules
    ../../home-manager/modules/dotfiles.nix

    # Packages
    ../../home-manager/packages/cli/common-cli.nix
    ../../home-manager/packages/cli/fish.nix
    ../../home-manager/packages/cli/git.nix
    ../../home-manager/packages/editors/helix.nix
  ];

  # Ship dotfiles with each deploy instead of linking into a ~/dotfiles clone
  dotfiles.mutable = false;

  home.stateVersion = "26.11";
}
