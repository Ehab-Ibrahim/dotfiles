{pkgs, ...}: {
  services.opencloud = {
    enable = true;

    # Rolling release in the locked nixpkgs. The production package is older.
    package = pkgs.opencloud;

    # OpenCloud hard-requires an https:// external URL for its OIDC issuer.
    url = "https://cloud.horus";
    address = "127.0.0.1";
    port = 9200;
    stateDir = "/srv/opencloud";

    environment = {
      OC_INSECURE = "true";
      PROXY_TLS = "false";
    };

    environmentFile = "/etc/opencloud.env";
  };

  # /srv is a separate volume on horus.
  systemd.services.opencloud.unitConfig.RequiresMountsFor = "/srv/opencloud";
  systemd.services.opencloud-init-config.unitConfig.RequiresMountsFor = "/srv/opencloud";

  # Bare hostname enables Caddy automatic HTTPS. For a non-public name such as
  # cloud.horus, Caddy issues a certificate from its local CA. Clients must trust
  # that CA, or use a real domain / Tailscale cert later.
  services.caddy.virtualHosts."cloud.horus".extraConfig = ''
    tls internal
    reverse_proxy 127.0.0.1:9200
  '';

  # Required for LAN clients to reach Caddy's HTTPS listener.
  networking.firewall.allowedTCPPorts = [443];
}
