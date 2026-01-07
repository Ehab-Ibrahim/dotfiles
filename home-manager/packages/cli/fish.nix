{
  pkgs,
  config,
  ...
}: {
  programs.fish = {
    enable = true;
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../../";
      "....." = "cd ../../../../";

      "gl" = "git log --oneline --graph --color --exclude=refs/stash --all --decorate";
    };

    shellAbbrs = {
      # nix abbreviations
      hm = "home-manager";
      hms.function = "__hms_expansion";
      ncg = "nix-collect-garbage";
      nrn = "sudo nixos-rebuild switch --flake .#nixos";
    };

    functions = {
      __hms_expansion = ''
        set HMS "home-manager switch --flake ${config.nixConfigRoot}"
        set SPEC_PATH "${config.xdg.dataHome}/home-manager/specialisation"
        if test -e $SPEC_PATH
          set HMS "$HMS -c $(cat $SPEC_PATH)"
        end
        echo $HMS
      '';
      fish_greeting = ''
        set_color $fish_color_autosuggestion
        uname -nmsr

        # TODO: `command -q -s` only works on fish 2.5+, so hold off on that for now
        command -s uptime >/dev/null
        and command uptime

        set_color normal
      '';
    };

    interactiveShellInit = ''
      # Change fzf files keybinding to ctrl+o
      fzf_configure_bindings --directory=\co
    '';

    plugins = with pkgs.fishPlugins; [
      {
        name = "fzf-fish";
        src = fzf-fish.src;
      }
      {
        name = "bass";
        src = bass.src;
      }
    ];
  };

  # Programs integrations
  programs.eza.enableFishIntegration = true;
  programs.starship.enableFishIntegration = true;
  programs.zoxide.enableFishIntegration = true;
}
