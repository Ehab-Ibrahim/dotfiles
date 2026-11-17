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

      mutable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Link into the repo checkout, so edits apply without a switch. When
          false, files are copied into the Nix store and no checkout is needed.
        '';
      };

      symlink = lib.mkOption {
        type = lib.types.functionTo lib.types.path;
        readOnly = true;
        description = "Helper to resolve a relative path inside dotfiles.";
      };
    };
  };

  config.dotfiles.symlink = relativePath:
    if config.dotfiles.mutable
    then config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/${relativePath}"
    # Own store path per file/dir, so only what's used is deployed (a plain
    # path would pull in the whole flake source)
    else
      builtins.path {
        path = ../../dotfiles + "/${relativePath}";
        name = "dotfiles-" + lib.replaceStrings ["/"] ["-"] relativePath;
      };
}
