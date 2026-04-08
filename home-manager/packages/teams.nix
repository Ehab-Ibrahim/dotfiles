{pkgs, ...}: {
  home.gui-apps.packages = [pkgs.teams-for-linux];
  xdg.configFile."autostart/teams.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Exec=${pkgs.teams-for-linux}/bin/teams-for-linux --minimized
    Name=Microsoft Teams
    X-GNOME-Autostart-enabled=true
  '';
}
