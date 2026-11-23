# Tailscale: remote access. After a reinstall: `sudo tailscale up`.
{...}: {
  services.tailscale = {
    enable = true;
    openFirewall = true; # direct (peer-to-peer) connections
    disableUpstreamLogging = true;
  };

  # Devices on the tailnet reach every service, like on the LAN
  networking.firewall.trustedInterfaces = ["tailscale0"];
}
