# Reverse proxy for <service>.horus; vhosts live with the services they expose.
{...}: {
  services.caddy.enable = true;

  # Caddy's HTTP listener
  networking.firewall.allowedTCPPorts = [80];
}
