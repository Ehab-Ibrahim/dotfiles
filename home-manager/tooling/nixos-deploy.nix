{
  config,
  pkgs,
  ...
}: {
  imports = [../modules/dotfiles.nix];

  home.packages = [
    pkgs.nixos-rebuild
  ];

  # Deploy a NixOS host, but avoid garbage collection cleaning build artifacts
  # Force garbage collection by deleting ~/.cache/nix/<host>-toplevel
  programs.fish.functions.nixos-deploy = {
    description = "Deploy a NixOS host, keeping the build as a GC root";
    body = ''
      set -l host $argv[1]
      if test -z "$host"
        echo "usage: nixos-deploy <host>" >&2
        return 1
      end

      set -l root ${config.home.homeDirectory}/.cache/nix/$host-toplevel
      mkdir -p (dirname $root)
      and nix build --out-link $root "${config.nixConfigRoot}#nixosConfigurations.$host.config.system.build.toplevel"
      and nixos-rebuild switch --flake ${config.nixConfigRoot}#$host --target-host $host --sudo --ask-sudo-password --use-substitutes $argv[2..]
    '';
  };
}
