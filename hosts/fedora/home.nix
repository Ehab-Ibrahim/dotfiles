# Standalone home-manager config for the `fedora` workstation (non-NixOS).
# Deployed with `home-manager switch --flake .#eibrahim@fedora`.
{vars, ...}: {
  home = {
    username = vars.username;
    homeDirectory = "/home/${vars.username}";
    stateVersion = "26.05";
  };

  imports = [
    ../../home-manager/settings
    ../../home-manager/shell
    ../../home-manager/tooling
    ../../home-manager/graphical
    ../../home-manager/services
  ];
}
