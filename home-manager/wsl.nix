# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{vars, ...}: {
  home = {
    username = vars.username;
    homeDirectory = "/home/${vars.username}";
  };

  # Wrap GUI apps using nixgl
  home.gui-apps.nixgl-wrap = vars.use-nixgl;

  # WSLg provides a display but doesn't import it into the systemd user environment
  # the way a desktop display manager would — set it explicitly for all user services
  systemd.user.sessionVariables = {
    DISPLAY = ":0";
    WAYLAND_DISPLAY = "wayland-0";
  };

  # You can import other home-manager modules here
  imports = [
    # Modules
    ./modules
    # Common nix and home-manager settings
    ./home-settings.nix
    # Packages
    ./packages/cli
    ./packages/editors
    ./packages/ssh
  ];
}
