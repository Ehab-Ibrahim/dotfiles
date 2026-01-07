{
  lib,
  config,
  ...
}: {
  options = {
    nixConfigRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/dotfiles";
      description = "Path to my nix config.";
    };

    dotfiles = {
      path = lib.mkOption {
        type = lib.types.str;
        default = "${config.nixConfigRoot}/dotfiles";
        description = "Path to my dotfiles directory.";
      };

      symlink = lib.mkOption {
        type = lib.types.functionTo lib.types.path;
        readOnly = true;
        description = "Helper to resolve a relative path inside dotfiles, using mkOutOfStoreSymlink.";
      };
    };
  };

  config.dotfiles.symlink = relativePath:
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/${relativePath}";
}
