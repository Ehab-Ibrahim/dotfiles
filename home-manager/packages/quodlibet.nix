{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    pkgs.quodlibet-full
  ];
  home.file.".config/quodlibet/config".source = config.dotfiles.symlink "quodlibet/config";
}
