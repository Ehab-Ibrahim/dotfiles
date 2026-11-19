{pkgs, ...}: {
  imports = [
    ../../home-manager/settings/home-manager.nix
    ../../home-manager/shell
    ../../home-manager/tooling/common-cli.nix
    ../../home-manager/tooling/git.nix
    ../../home-manager/tooling/helix.nix
  ];

  # Ship dotfiles with each deploy instead of linking into a ~/dotfiles clone
  dotfiles.mutable = false;

  home.stateVersion = "26.11";
}
