{lib, ...}: let
  rbwRuntimeDir = "$XDG_RUNTIME_DIR/rbw";
  rbwSocket = "${rbwRuntimeDir}/ssh-agent-socket";
  flatpakAppId = "com.nomachine.nxplayer";
  # Activation scripts have no /usr/bin on PATH.
  flatpakBin = "/usr/bin/flatpak";
in {
  # Installed via Flathub, not nixpkgs: nixpkgs pins a vendor tarball URL that
  # NoMachine removes on every release, breaking `nix flake update`.
  home.activation.installNomachineFlatpak = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # gpg/gpgconf (needed by flatpak's GPGME) also live in /usr/bin.
    export PATH="/usr/bin:/bin:$PATH"
    if ! ${flatpakBin} info --user ${flatpakAppId} &>/dev/null; then
      verboseEcho "Installing NoMachine client (${flatpakAppId}) via Flatpak"
      run ${flatpakBin} install --user --noninteractive flathub ${flatpakAppId}
    fi

    # Point the app at RBW's ssh-agent, bypassing Flatpak's ssh-auth socket
    # passthrough (which would otherwise bind whatever agent the desktop
    # session already exports, e.g. gcr-ssh-agent).
    if systemctl --user is-active --quiet rbw-agent.service; then
      run ${flatpakBin} override --user --nosocket=ssh-auth ${flatpakAppId}
      run ${flatpakBin} override --user --filesystem="${rbwRuntimeDir}:ro" ${flatpakAppId}
      run ${flatpakBin} override --user --env=SSH_AUTH_SOCK="${rbwSocket}" ${flatpakAppId}
    fi
  '';
}
