{
  config,
  pkgs,
  lib,
  ...
}: let
  rbwSocket = "$XDG_RUNTIME_DIR/rbw/ssh-agent-socket";

  nomachineWrapper = pkgs.writeShellApplication {
    name = "nomachine-wrapper.sh";
    runtimeInputs = [pkgs.systemdMinimal];
    text = ''
      # Path to RBW Socket
      RBW_SOCK="${rbwSocket}"

      # Check if the RBW agent service is running
      if systemctl --user is-active --quiet rbw-agent.service; then
        # If yes, point NoMachine to RBW
        export SSH_AUTH_SOCK="$RBW_SOCK"
        echo "RBW Agent found and active!" | systemd-cat -t nomachine-wrapper
      else
        echo "RBW Agent not found or not responding." | systemd-cat -t nomachine-wrapper
      fi

      echo "Using: $SSH_AUTH_SOCK" | systemd-cat -t nomachine-wrapper

      # Launch NoMachine Player
      exec ${pkgs.nomachine-client}/bin/nxplayer "$@"
    '';
  };

  nomachineWrapperWithNixGL = config.lib.gui-apps.wrapApp nomachineWrapper;
  nomachineWrapperPath = "${nomachineWrapperWithNixGL}/bin/nomachine-wrapper.sh";

  # Create a custom package with symlinks to the original package
  # Modify the .desktop files of the custom package to use the wrapper script
  # Wrap nomachineWrapper with NixGL for GPU acceleration
  nomachine-custom = pkgs.symlinkJoin {
    name = "nomachine-client-custom";
    paths = [pkgs.nomachine-client];
    postBuild = ''
      cd $out/share/applications
      for f in *.desktop; do
        cp --remove-destination "$(readlink -f "$f")" "$f"
        sed -i 's|/nix/store/[^"]*/bin/nxplayer|${nomachineWrapperPath}|g' "$f"
      done
    '';
  };
in {
  # NoMachine
  home.packages = [nomachine-custom];
}
