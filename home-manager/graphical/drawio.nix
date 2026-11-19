{pkgs, ...}: {
  imports = [../modules/gui-apps.nix];
  home.gui-apps.packages = [pkgs.drawio];
}
