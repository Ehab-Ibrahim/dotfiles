{
  secrets,
  pkgs,
  lib,
  ...
}: let
  rbwSocket = "$XDG_RUNTIME_DIR/rbw/ssh-agent-socket";
in {
  # RBW CLI
  programs.rbw = {
    enable = true;
    settings = {
      email = secrets.gmail;
      lock_timeout = 4 * 3600;
      pinentry = pkgs.pinentry-gnome3;
    };
  };

  systemd.user.services.rbw-agent = {
    Unit = {
      Description = "rbw SSH agent";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "forking";
      ExecStart = "${pkgs.rbw}/bin/rbw login";
      Restart = "on-failure";
      Environment = ''
        PATH=${lib.makeBinPath [pkgs.rbw pkgs.pinentry-gnome3]}
      '';
      PIDFile = "%t/rbw/pidfile";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  programs.fish.shellInit = ''
    set -x SSH_AUTH_SOCK "${rbwSocket}"
  '';
}
