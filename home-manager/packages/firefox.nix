{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.firefox = {
    enable = true;
    package = config.lib.gui-apps.wrapApp pkgs.firefox;
  };
}
