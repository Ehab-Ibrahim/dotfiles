{
  config,
  pkgs,
  lib,
  ...
}: let
  # Wallpapers to choose from
  wallpapers = {
    dark = "/home/eibrahim/Pictures/Wallpapers/1-catppuccin.png";
    light = "/home/eibrahim/Pictures/Wallpapers/1-catppuccin-latte.png";
  };

  # Set style based on catppuccin flavor
  style =
    if config.catppuccin.flavor == "latte"
    then "light"
    else "dark";

  # Set some helper paths
  cosmic_conf = "~/.config/cosmic";
  cosmic_paths = {
    is_dark = "${cosmic_conf}/com.system76.CosmicTheme.Mode/v1/is_dark";
    wallpaper = "${cosmic_conf}/com.system76.CosmicBackground/v1/all";
  };

  # Choose wallpaper based on style
  wallpaper_path = wallpapers.${style};

  # Commands used in activation script
  cosmic_cmds = {
    mode = ''
      printf ${lib.boolToString (style == "dark")} > ${cosmic_paths.is_dark}
    '';
    wallpaper = ''
      if [ -f ${cosmic_paths.wallpaper} ]; then
        sed -i -E 's|Path\(".+"\)|Path\("${wallpaper_path}"\)|g' ${cosmic_paths.wallpaper}
      fi
    '';
  };
in {
  home.activation.cosmic_mode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${cosmic_cmds.mode}
    ${cosmic_cmds.wallpaper}
  '';
}
