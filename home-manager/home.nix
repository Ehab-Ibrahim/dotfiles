# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{vars, ...}: {
  home = {
    username = vars.username;
    homeDirectory = "/home/${vars.username}";
  };

  # Wrap GUI apps using nixgl
  home.gui-apps.nixgl-wrap = vars.use-nixgl;

  # You can import other home-manager modules here
  imports = [
    # Modules
    ./modules
    # Common nix and home-manager settings
    ./home-settings.nix
    # Packages
    ./packages/catppuccin
    ./packages/cli
    ./packages/drawio.nix
    ./packages/editors
    ./packages/firefox.nix
    ./packages/nomachine.nix
    ./packages/quodlibet.nix
    ./packages/ssh
    ./packages/terminals
  ];
}
