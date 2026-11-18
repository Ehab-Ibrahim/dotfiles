{
  pkgs,
  config,
  ...
}: {
  programs.fish = {
    enable = true;

    # As a login shell, fish doesn't read ~/.profile, so load Nix's env here.
    loginShellInit = ''
      if test -e ${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.fish
        source ${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.fish
      end
    '';

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
    };

    functions = {
      # Deploy to horus, but avoid garbage collection cleaning build artifacts
      # Force garbage collection by deleting ~/.cache/nix/horus-toplevel
      deploy-horus = {
        description = "Deploy horus, keeping the build as a GC root";
        body = ''
          set -l root ${config.home.homeDirectory}/.cache/nix/horus-toplevel
          mkdir -p (dirname $root)
          and nix build --out-link $root "${config.nixConfigRoot}#nixosConfigurations.horus.config.system.build.toplevel"
          and nixos-rebuild switch --flake ${config.nixConfigRoot}#horus --target-host horus --sudo --ask-sudo-password --use-substitutes
        '';
      };
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
