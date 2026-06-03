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
      pinentry = pkgs.pinentry-qt;
    };
  };

  systemd.user.services.rbw-agent = {
    Unit = {
      Description = "rbw SSH agent";
      After = ["default.target"];
    };
    Service = {
      Type = "forking";
      ExecStart = "${pkgs.rbw}/bin/rbw login";
      Restart = "on-failure";
      Environment = [
        "PATH=${lib.makeBinPath [pkgs.rbw pkgs.pinentry-qt]}"
      ];
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
