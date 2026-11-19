# Standalone home-manager config for `magics-ehab` (WSL on Windows).
# Deployed with `home-manager switch --flake .#eibrahim@magics-ehab`.
{vars, ...}: {
  home = {
    username = vars.username;
    homeDirectory = "/home/${vars.username}";
    stateVersion = "26.05";
  };

  # WSLg provides a display but doesn't import it into the systemd user environment
  # the way a desktop display manager would — set it explicitly for all user services
  systemd.user.sessionVariables = {
    DISPLAY = ":0";
    WAYLAND_DISPLAY = "wayland-0";
  };

  imports = [
    ../../home-manager/settings
    ../../home-manager/shell
    ../../home-manager/tooling
    ../../home-manager/services
  ];
}
