# Standalone home-manager config for the `fedora` workstation (non-NixOS).
# Deployed with `home-manager switch --flake .#eibrahim@fedora`.
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
    ../../home-manager/modules
    # Common nix and home-manager settings
    ../../home-manager/home-settings.nix
    # Packages
    ../../home-manager/packages/cli
    ../../home-manager/packages/drawio.nix
    ../../home-manager/packages/editors
    ../../home-manager/packages/firefox.nix
    ../../home-manager/packages/quodlibet.nix
    ../../home-manager/packages/ssh
    ../../home-manager/packages/terminals
  ];
}
