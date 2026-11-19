{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [../modules/gui-apps.nix];
  programs.firefox = {
    enable = true;
    package = config.lib.gui-apps.wrapApp pkgs.firefox;
  };
}
