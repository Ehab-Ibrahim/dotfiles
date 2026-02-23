{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    bat
    btop
    delta
    direnv
    dust
    eza
    fd
    fzf
    lazygit
    nh
    nushell
    ripgrep
    starship
    yazi
    zellij
    zoxide
  ];

  # Enables for stylix
  programs.bat.enable = true;
  programs.fzf.enable = true;
  programs.yazi.enable = true;

  # Btop
  programs.btop = {
    enable = true;
    settings.vim_keys = true;
  };

  # Delta
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
    };
  };
  programs.lazygit.settings.git.pagers = [
    {pager = "delta --paging=never";}
  ];

  # Direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Eza
  programs.eza = {
    enable = true;
    colors = "auto";
    git = true;
    icons = "auto";
  };

  # Lazygit
  programs.lazygit.enable = true;
  # For some reason, If I don't add a settings entry, not config.yml
  # file will be created, breaking lazygit
  # Make sure to at least add something in the settings
  programs.lazygit.settings.update.method = "never";

  # Starship
  programs.starship.enable = true;
  home.file.".config/starship.toml".source = config.dotfiles.symlink "starship.toml";

  # Zellij
  programs.zellij.enable = true;
  home.file.".config/zellij/" = {
    source = config.dotfiles.symlink "zellij";
    recursive = true;
  };

  # Zoxide
  programs.zoxide.enable = true;
}
