{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    uv
  ];
  programs.fish.interactiveShellInit = ''
    # Generate uv completions
    uv generate-shell-completion fish | source
    uvx --generate-shell-completion fish | source
  '';
}
