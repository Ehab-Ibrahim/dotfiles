{
  secrets,
  config,
  ...
}: {
  home.file.".ssh/config".source = config.dotfiles.symlink "ssh/config";
  home.file.".ssh/config.d/magics".source = "${secrets}/magics_ssh";
}
