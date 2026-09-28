{
  secrets,
  config,
  pkgs,
  ...
}: let
  # A ControlMaster that survives suspend keeps a dead TCP connection, and new
  # sessions hang on it. Close every master (ControlPath ~/.ssh/cm-%C, set in
  # magics_ssh) when logind announces sleep, and again on resume in case the
  # first close lost the race against the freeze
  ssh-mux-sleep = pkgs.writeShellApplication {
    name = "ssh-mux-sleep";
    runtimeInputs = [pkgs.glib pkgs.openssh pkgs.coreutils];
    text = ''
      shopt -s nullglob
      gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 |
        while read -r line; do
          [[ $line == *.PrepareForSleep\ * ]] || continue
          echo "$line"
          for sock in ~/.ssh/cm-*; do
            if timeout 3 ssh -F none -O exit -o ControlPath="$sock" _; then
              echo "closed $sock"
            fi
          done
        done
    '';
  };
in {
  home.file.".ssh/config".source = config.dotfiles.symlink "ssh/config";
  home.file.".ssh/config.d/magics".source = "${secrets}/magics_ssh";

  systemd.user.services.ssh-mux-sleep = {
    Unit = {
      Description = "Close ssh ControlMaster connections on suspend";
    };
    Service = {
      ExecStart = "${ssh-mux-sleep}/bin/ssh-mux-sleep";
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
