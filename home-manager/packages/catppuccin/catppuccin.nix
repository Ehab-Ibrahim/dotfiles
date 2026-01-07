{
  config,
  pkgs,
  lib,
  ...
}: let
  toggle-theme-desktop = {
    name = "Toggle Theme";
    type = "Application";
    exec = "toggle-theme";
    icon = ./theme-light-dark.svg;
  };
in {
  catppuccin = {
    flavor = lib.mkDefault "macchiato";

    # Targets
    alacritty.enable = true;
    bat.enable = true;
    btop.enable = true;
    delta.enable = true;
    eza.enable = true;
    fish.enable = true;
    fzf.enable = true;
    kitty.enable = true;
    yazi.enable = true;
  };

  specialisation.light.configuration = {
    catppuccin.flavor = "latte";
    xdg.dataFile."home-manager/specialisation".text = "light";
  };

  # Fish function to reload theme
  programs.fish.interactiveShellInit = ''
    # FZF colors are set in hm_session_vars, and it's only sourced once per session
    # Override FZF_DEFAULT_OPTS value in our fish config to force color update
    set -gx FZF_DEFAULT_OPTS '${config.home.sessionVariables.FZF_DEFAULT_OPTS}'

    function reload-theme --on-variable _reload_theme
      eval (rg -N "^fish_config theme choose .+" ~/.config/fish/config.fish)
    end
  '';

  # Manually change Helix, Zellij, and Neovim themes on activation
  home.activation = lib.mkMerge [
    (lib.mkIf config.programs.helix.enable {
      helix_theme = lib.hm.dag.entryAfter ["writeBoundary"] ''
        HX_CONFIG=~/.config/helix/config.toml
        if [ -f $HX_CONFIG ]; then
          sed -i -E 's/theme = ".+"/theme = "catppuccin_${config.catppuccin.flavor}"/g' $HX_CONFIG
          # Reload Helix if any instance is running
          if ${pkgs.procps}/bin/pgrep hx >/dev/null 2>&1; then
            ${pkgs.procps}/bin/pkill -USR1 hx
          fi
        fi
      '';
    })
    (lib.mkIf config.programs.zellij.enable {
      zellij_theme = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ZELLIJ_CONFIG=~/.config/zellij/config.kdl
        if [ -f $ZELLIJ_CONFIG ]; then
          sed -i -E 's/theme ".+"/theme "catppuccin-${config.catppuccin.flavor}"/g' $ZELLIJ_CONFIG
        fi
      '';
    })
    (lib.mkIf config.programs.neovim.enable {
      nvim_theme = lib.hm.dag.entryAfter ["writeBoundary"] ''
        NVIM_CONFIG=~/.config/nvim/lua/plugins/colorscheme.lua
        if [ -f $NVIM_CONFIG ]; then
          sed -i -E 's/colorscheme = ".+"/colorscheme = "catppuccin-${config.catppuccin.flavor}"/g' $NVIM_CONFIG
        fi
      '';
    })
  ];

  home.packages = [
    (pkgs.writeShellApplication {
      name = "toggle-theme";
      runtimeInputs = with pkgs; [ripgrep fish];
      text = ''
        # Read all home-manager generations and store in HM_GENERATIONS
        mapfile -t HM_GENERATIONS < <(home-manager generations | rg -o '/[^ ]*')
        CURRENT_GEN="''${HM_GENERATIONS[0]}"
        PREV_GEN="''${HM_GENERATIONS[1]:-}"

        # Check if we're in dark mode
        # `specialisation` path holds either `light` or is absent (dark)
        SPEC_PATH="${config.xdg.dataHome}/home-manager/specialisation"
        if [ ! -f "$SPEC_PATH" ]; then
          # We're in Dark mode
          "$CURRENT_GEN/specialisation/light/activate"
        else
          # We're in Light mode
          if [ -d "$CURRENT_GEN/specialisation" ]; then
            # In some cases, the current generation holds both default (dark) and light
            # activation scripts. In this case, change to dark from CURRENT_GEN.
            # This happens when using `home-manager switch -c light`
            "$CURRENT_GEN/activate"
          elif [ -d "$PREV_GEN" ]; then
            # Else, probably previous generation holds dark mode.
            "$PREV_GEN/activate"
          else
            # If no previous generation is found (garbage collected),
            # fallback to creating a new generation with home-manager switch.
            home-manager switch --flake ${config.nixConfigRoot}
          fi
        fi
        fish -c "set -U _reload_theme (date +%s)"
      '';
    })
  ];

  # Create .desktop file for theme toggling
  xdg.desktopEntries.toggle-theme = toggle-theme-desktop;
}
