{
  config,
  pkgs,
  ...
}: {
  programs.neovim.enable = true;
  # Avoid conflicting with our own recursive nvim symlink below
  programs.neovim.sideloadInitLua = true;

  # Symbolic links to dotfiles
  home.file.".config/nvim/" = {
    source = config.dotfiles.symlink "nvim";
    recursive = true;
  };
}
