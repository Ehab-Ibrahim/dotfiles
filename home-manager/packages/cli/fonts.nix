{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    cozette
    pixel-code
    nerd-fonts.jetbrains-mono
  ];
}
