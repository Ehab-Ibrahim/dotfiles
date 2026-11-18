# Standalone home-manager config for `magics-ehab` (WSL on Windows).
# Deployed with `home-manager switch --flake .#eibrahim@magics-ehab`.
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
    ../../home-manager/modules
    # Common nix and home-manager settings
    ../../home-manager/home-settings.nix
    # Packages
    ../../home-manager/packages/cli
    ../../home-manager/packages/editors
    ../../home-manager/packages/ssh
  ];
}
