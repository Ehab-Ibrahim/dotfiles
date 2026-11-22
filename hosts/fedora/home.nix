# Standalone home-manager config for the `fedora` workstation (non-NixOS).
# Deployed with `home-manager switch --flake .#eibrahim@fedora`.
{
  vars,
  lib,
  config,
  ...
}: {
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

  # KDE refuses launching .desktop files without executable bit
  # Copy .desktop files with the correct permissions to $XDG_DATA_HOME/applications

  home.activation.kdeDesktopEntries = lib.hm.dag.entryAfter ["installPackages"] ''
    appDir="${config.xdg.dataHome}/applications"
    profileApps="${config.home.homeDirectory}/.nix-profile/share/applications"

    mkdir -p "$appDir"
    for desktop in "$profileApps"/*.desktop; do
      [ -e "$desktop" ] || continue
      name=$(basename "$desktop")
      install -m 755 "$desktop" "$appDir/$name"
    done
  '';
}
