# Reverse proxy and TLS for <service>.hooba.be.
{...}: {
  # Wildcard certificate via DNS-01; no inbound port is needed for validation.
  security.acme = {
    acceptTerms = true;
    defaults.email = "hooba91@gmail.com";
    certs."hooba.be" = {
      domain = "*.hooba.be";
      extraDomainNames = ["hooba.be"];
      dnsProvider = "infomaniak";
      # Root-only token file loaded as a systemd credential (lego uses _FILE).
      credentialFiles."INFOMANIAK_ACCESS_TOKEN_FILE" = "/var/lib/acme-token";
    };
  };

  services.caddy = {
    enable = true;
    openFirewall = true; # 80/443 on the LAN
  };
}
