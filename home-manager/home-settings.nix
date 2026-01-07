{pkgs, ...}: {
  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    package = pkgs.nix;
    settings = {
      extra-experimental-features = ["nix-command" "flakes"];
    };
  };

  # Enable home-manager
  programs.home-manager.enable = true;
  news.display = "silent";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
