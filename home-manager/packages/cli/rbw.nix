{
  secrets,
  pkgs,
  lib,
  ...
}: let
  rbwSocket = "$XDG_RUNTIME_DIR/rbw/ssh-agent-socket";

  # rbw-agent strips display vars from pinentry; re-read them from systemd at prompt time
  pinentry-rbw = pkgs.writeShellScriptBin "pinentry-rbw" ''
    display_vars=$(
      ${pkgs.systemd}/bin/systemctl --user show-environment |
        ${pkgs.gnugrep}/bin/grep -E '^(DISPLAY|WAYLAND_DISPLAY|XAUTHORITY)='
    )
    exec ${pkgs.coreutils}/bin/env $display_vars ${pkgs.pinentry-qt}/bin/pinentry-qt "$@"
  '';
in {
  # RBW CLI
  programs.rbw = {
    enable = true;
    settings = {
      email = secrets.gmail;
      lock_timeout = 4 * 3600;
      pinentry = pinentry-rbw;
    };
  };

  systemd.user.services.rbw-agent = {
    Unit = {
      Description = "rbw SSH agent";
    };
    Service = {
      Type = "forking";
      ExecStart = "${pkgs.rbw}/bin/rbw-agent";
      Restart = "on-failure";
      PIDFile = "%t/rbw/pidfile";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  programs.fish.shellInit = ''
    set -x SSH_AUTH_SOCK "${rbwSocket}"
  '';
}
