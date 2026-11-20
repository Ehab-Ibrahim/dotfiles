# Remote access; log in once with `sudo tailscale up`.
{...}: {
  services.tailscale = {
    enable = true;
    openFirewall = true; # direct (peer-to-peer) connections
  };

  # Devices on the tailnet reach every service, like on the LAN
  networking.firewall.trustedInterfaces = ["tailscale0"];
}
