{
  config,
  pkgs,
  ...
}: {
  # Kitty dotfiles symlinked to `default.conf`, then included using nix
  home.file.".config/kitty/default.conf".source = config.dotfiles.symlink "kitty/kitty.conf";
  programs.kitty = {
    enable = true;
    package = config.lib.gui-apps.wrapApp pkgs.kitty;
    extraConfig = "include default.conf";
  };
}
