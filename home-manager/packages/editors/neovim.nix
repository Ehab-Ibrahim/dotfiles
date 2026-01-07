{
  config,
  pkgs,
  ...
}: {
  programs.neovim.enable = true;

  # Symbolic links to dotfiles
  home.file.".config/nvim/" = {
    source = config.dotfiles.symlink "nvim";
    recursive = true;
  };
}
