{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.alacritty = {
    enable = true;
    package = config.lib.gui-apps.wrapApp pkgs.alacritty;
    settings = {
      terminal.shell = "fish";
      font = {
        normal.family = lib.mkForce "JetBrainsMono Nerd Font";
        size = 12;
      };
      cursor = {
        style.shape = "Beam";
        style.blinking = "On";
        vi_mode_style.shape = "Block";
        vi_mode_style.blinking = "Off";
      };
      window = {
        decorations = "None";
        padding.x = 3;
        padding.y = 3;
        dynamic_padding = true;
      };
      keyboard.bindings = [
        {
          mode = "Vi";
          key = "q";
          action = "ToggleViMode";
        }
      ];
    };
  };
}
