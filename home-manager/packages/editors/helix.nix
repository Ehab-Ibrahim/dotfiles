{config, ...}: {
  programs.helix.enable = true;

  # Symbolic links to dotfiles
  home.file.".config/helix".source = config.dotfiles.symlink "helix";

  home.sessionVariables.EDITOR = "hx";
}
