# OpenCloud behind Caddy; optional Pocket ID integration is in ./pocketid-opencloud.nix.
{pkgs, ...}: {
  services.opencloud = {
    enable = true;

    # Rolling release; the production package is older.
    package = pkgs.opencloud;

    # Must be https even though Caddy terminates TLS.
    url = "https://cloud.hooba.be";
    address = "127.0.0.1";
    port = 9200;
    stateDir = "/srv/opencloud";

    environment = {
      OC_INSECURE = "true";
      PROXY_TLS = "false";
    };
  };

  # Resolve locally; don't depend on AdGuard.
  networking.hosts."127.0.0.1" = ["cloud.hooba.be"];

  # /srv is a separate volume.
  systemd.services.opencloud.unitConfig.RequiresMountsFor = "/srv/opencloud";
  systemd.services.opencloud-init-config.unitConfig.RequiresMountsFor = "/srv/opencloud";

  # Vhost here so disabling OpenCloud drops the proxy; reuse the wildcard cert.
  services.caddy.virtualHosts."cloud.hooba.be" = {
    useACMEHost = "hooba.be";
    extraConfig = "reverse_proxy 127.0.0.1:9200";
  };
}
