# AdGuard Home: DNS ad-blocking and the local *.horus rewrites.
{...}: {
  services.adguardhome = {
    enable = true;
    openFirewall = true; # web UI only
  };

  # Vhost lives here so disabling AdGuard also drops its reverse proxy.
  services.caddy.virtualHosts."http://adguard.horus".extraConfig = "reverse_proxy 127.0.0.1:3000";

  # openFirewall does not cover the resolver itself
  networking.firewall.allowedTCPPorts = [53];
  networking.firewall.allowedUDPPorts = [53];
}
