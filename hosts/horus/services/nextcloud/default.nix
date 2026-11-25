# Nextcloud at https://nextcloud.hooba.be.
# State: /srv/nextcloud, /srv/postgresql; back up before reinstall.
{pkgs, ...}: let
  domain = "nextcloud.hooba.be";
  port = 8081;
  stateDir = "/srv/nextcloud";
in {
  # Optional Pocket ID login; drop this import to use local accounts only.
  imports = [./pocketid.nix];

  # Resolve locally; don't depend on AdGuard.
  networking.hosts."127.0.0.1" = [domain];

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
    hostName = domain;
    home = stateDir;

    # Caddy terminates TLS.
    https = false;

    config.dbtype = "pgsql";
    database.createLocally = true;
    configureRedis = true;
    caching.apcu = true;
    appstoreEnable = false;

    settings = {
      # Links built during web requests; Caddy talks plain HTTP to nginx.
      overwriteprotocol = "https";
      # Links built outside web requests (cron jobs, occ).
      "overwrite.cli.url" = "https://${domain}";
      # Read the real client IP from Caddy's X-Forwarded-For.
      trusted_proxies = ["127.0.0.1"];
    };
  };

  # /srv must be mounted first.
  systemd.services.nextcloud-setup.unitConfig.RequiresMountsFor = stateDir;

  # Custom dataDir isn't provisioned by the postgres module.
  services.postgresql.dataDir = "/srv/postgresql";
  systemd.tmpfiles.rules = ["d /srv/postgresql 0700 postgres postgres - -"];

  # Loopback port; Caddy owns 80/443.
  services.nginx.virtualHosts.${domain} = {
    listen = [
      {
        addr = "127.0.0.1";
        port = port;
      }
    ];
  };

  services.caddy.virtualHosts.${domain} = {
    useACMEHost = "hooba.be";
    extraConfig = "reverse_proxy 127.0.0.1:${toString port}";
  };

  # First boot: no admin password is stored in the Nix store. Create it with:
  #   sudo nextcloud-occ user:add admin
  #   sudo nextcloud-occ group:adduser admin admin
}
