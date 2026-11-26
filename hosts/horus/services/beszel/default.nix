# Beszel at https://pulse.hooba.be: system monitoring hub plus a local agent.
# State: /var/lib/beszel-hub (history, users, hub SSH key). Nothing to do after
# a reinstall; restore it to keep history.
{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = "pulse.hooba.be";
  hub = config.services.beszel.hub;
  agentPort = 45876;

  # Systems are synced from here on every start; ones not listed are deleted.
  systems = pkgs.writeText "beszel-config.yml" (builtins.toJSON {
    systems = [
      {
        name = config.networking.hostName;
        host = "127.0.0.1";
        port = agentPort;
      }
    ];
  });

  # The agent only accepts the hub's key: create it before the hub would, and
  # hand the public half to the agent (systemd reads EnvironmentFile as root).
  prepare = pkgs.writers.writeNu "beszel-hub-prepare" ''
    let key = "beszel_data/id_ed25519"
    if not ($key | path exists) {
      ^${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C "" -f $key
    }
    let public_key = ^${pkgs.openssh}/bin/ssh-keygen -y -f $key
    $"KEY=($public_key)\n" | save --force agent.env
    ^${pkgs.coreutils}/bin/ln -sfn ${systems} beszel_data/config.yml
  '';
in {
  # Optional Pocket ID login; without it, create the first user in the web UI.
  imports = [./pocketid.nix];

  services.beszel.hub = {
    enable = true;
    environment = {
      APP_URL = "https://${domain}";
      # Every user sees every system (incl. ones signing in via Pocket ID).
      SHARE_ALL_SYSTEMS = "true";
    };
  };
  # Runs in the state dir after the module's migrations.
  systemd.services.beszel-hub.serviceConfig.ExecStartPre = lib.mkAfter ["${prepare}"];

  services.beszel.agent = {
    enable = true;
    environment = {
      # Loopback only; the hub is on this host.
      LISTEN = "127.0.0.1:${toString agentPort}";
      EXTRA_FILESYSTEMS = "/srv";
    };
    environmentFile = "${hub.dataDir}/agent.env";
  };
  systemd.services.beszel-agent = {
    after = ["beszel-hub.service"];
    wants = ["beszel-hub.service"];
  };

  services.caddy.virtualHosts.${domain} = {
    useACMEHost = "hooba.be";
    extraConfig = "reverse_proxy ${hub.host}:${toString hub.port}";
  };

  # Resolve locally; don't depend on AdGuard.
  networking.hosts."127.0.0.1" = [domain];
}
