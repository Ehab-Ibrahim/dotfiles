# Pocket ID at https://id.hooba.be: passkey OIDC provider; keys come from sops.
# State: /var/lib/pocket-id. After a reinstall: restore it, or create the admin
# at https://id.hooba.be/setup and enroll a passkey.
{
  config,
  lib,
  ...
}: let
  domain = "id.hooba.be";
  port = 1411;
in {
  # services.pocket-id.provision: groups and clients for other services.
  imports = [./provision.nix];

  sops.secrets = {
    pocket_id_encryption_key = {};
    pocket_id_static_api_key = {};
  };

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://${domain}";
      TRUST_PROXY = true;
      # Loopback only: Caddy is the sole entry point (tailscale0 is a trusted interface).
      HOST = "127.0.0.1";
      PORT = port;
    };
    # Passed as *_FILE credentials; values must have no trailing newline.
    credentials = {
      ENCRYPTION_KEY = config.sops.secrets.pocket_id_encryption_key.path;
      STATIC_API_KEY = config.sops.secrets.pocket_id_static_api_key.path;
    };
  };

  # Pocket ID reports readiness, so units ordered after it can call its API
  # right away (the module defaults to "simple").
  systemd.services.pocket-id.serviceConfig.Type = lib.mkForce "notify";

  # Vhost here so disabling Pocket ID drops the proxy.
  services.caddy.virtualHosts.${domain} = {
    useACMEHost = "hooba.be";
    extraConfig = "reverse_proxy 127.0.0.1:${toString port}";
  };

  # Resolve locally; don't depend on AdGuard.
  networking.hosts."127.0.0.1" = [domain];
}
