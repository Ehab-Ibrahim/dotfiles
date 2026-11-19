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
}
