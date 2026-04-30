{
  config,
  inputs,
  pkgs,
  ...
}: {
  programs.helix = {
    enable = true;
    package = inputs.helix.packages.${pkgs.system}.default;
  };

  # Symbolic links to dotfiles
  home.file.".config/helix".source = config.dotfiles.symlink "helix";

  home.sessionVariables.EDITOR = "hx";
}
