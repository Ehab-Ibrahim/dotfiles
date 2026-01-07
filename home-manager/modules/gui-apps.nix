{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.home.gui-apps;

  # Unified wrapApp — can take a plain pkg or { package; offload ? false; }
  wrapApp = pkgSpec: let
    pkg =
      if builtins.isAttrs pkgSpec && pkgSpec ? package
      then pkgSpec.package
      else pkgSpec;

    offload =
      if builtins.isAttrs pkgSpec && pkgSpec ? offload
      then pkgSpec.offload
      else false;
  in
    if cfg.nixgl-wrap
    then
      if offload
      then config.lib.nixGL.wrapOffload pkg
      else config.lib.nixGL.wrap pkg
    else pkg;

  apps = map wrapApp cfg.packages;
in {
  options.home.gui-apps = {
    nixgl-wrap = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to wrap GUI apps with nixGL.
        If false, GUI apps are installed directly.
      '';
    };

    packages = lib.mkOption {
      type = with lib.types;
        listOf (either package attrs);
      default = [];
      description = ''
        List of GUI applications to install.

        Each element can be:
        - A plain package (e.g. pkgs.firefox)
        - Or an attrset { package = pkgs.firefox; offload = true; }
      '';
    };

    nixGL.defaultWrapper = lib.mkOption {
      type = lib.types.enum ["mesa" "mesaPrime" "nvidia" "nvidiaPrime"];
      default = "mesa";
      description = "The nixGL wrapper to use for default GPU mode.";
    };

    nixGL.offloadWrapper = lib.mkOption {
      type = lib.types.enum ["mesa" "mesaPrime" "nvidia" "nvidiaPrime"];
      default = "mesa";
      description = "The nixGL wrapper to use for offload GPU mode (Optimus laptops).";
    };
  };

  config = {
    lib.gui-apps.wrapApp = wrapApp;
    home.packages = apps;

    targets.genericLinux.nixGL = lib.mkIf cfg.nixgl-wrap {
      packages = inputs.nixgl.packages;
      defaultWrapper = cfg.nixGL.defaultWrapper;
      offloadWrapper = cfg.nixGL.offloadWrapper;

      installScripts = lib.unique [
        cfg.nixGL.defaultWrapper
        cfg.nixGL.offloadWrapper
      ];
    };
  };
}
