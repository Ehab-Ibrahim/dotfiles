# AdGuard Home: DNS ad-blocking; local *.hooba.be resolution is set in its UI.
{...}: {
  services.adguardhome = {
    enable = true;
    openFirewall = true; # web UI only
    # /etc/hosts entries would override the wildcard dnsrewrite rules.
    settings.dns.hostsfile_enabled = false;
  };

  # Vhost lives here so disabling AdGuard also drops its reverse proxy.
  services.caddy.virtualHosts."adguard.hooba.be" = {
    useACMEHost = "hooba.be";
    extraConfig = "reverse_proxy 127.0.0.1:3000";
  };

  # openFirewall does not cover the resolver itself
  networking.firewall.allowedTCPPorts = [53];
  networking.firewall.allowedUDPPorts = [53];
}
