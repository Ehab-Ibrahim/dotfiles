# OpenCloud at https://cloud.hooba.be; optional Pocket ID login is in ./pocketid.nix.
# State: /srv/opencloud and /etc/opencloud/opencloud.yaml (generated secrets; the
# data is unusable without it). After a reinstall: restore both.
{
  config,
  pkgs,
  ...
}: let
  domain = "cloud.hooba.be";
  cfg = config.services.opencloud;
in {
  imports = [./pocketid.nix];

  services.opencloud = {
    enable = true;

    # Rolling release; the production package is older.
    package = pkgs.opencloud;

    # Must be https even though Caddy terminates TLS.
    url = "https://${domain}";
    stateDir = "/srv/opencloud";

    # Replaces the module's default attrset, so OC_INSECURE must be restated.
    environment = {
      OC_INSECURE = "true";
      PROXY_TLS = "false";
      WEB_OPTION_DISABLE_SPONSOR_LINK = "true";
    };
  };

  # Resolve locally; don't depend on AdGuard.
  networking.hosts."127.0.0.1" = [domain];

  # /srv is a separate volume.
  systemd.services.opencloud.unitConfig.RequiresMountsFor = cfg.stateDir;

  # Vhost here so disabling OpenCloud drops the proxy; reuse the wildcard cert.
  services.caddy.virtualHosts.${domain} = {
    useACMEHost = "hooba.be";
    extraConfig = "reverse_proxy ${cfg.address}:${toString cfg.port}";
  };
}
