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
      # Start after graphical-session.target so DISPLAY is already imported into
      # the systemd environment before the agent forks.
      WantedBy = ["graphical-session.target"];
    };
  };

  # Fallback for WSL and headless servers where graphical-session.target never
  # activates. Fires 5s after the user session starts.
  systemd.user.timers.rbw-agent = {
    Timer = {
      OnActiveSec = "5s";
      RemainAfterElapse = false;
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  programs.fish.shellInit = ''
    set -x SSH_AUTH_SOCK "${rbwSocket}"
  '';
}
