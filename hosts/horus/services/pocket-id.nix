# Pocket ID at https://id.hooba.be; keys come from sops.
{config, ...}: {
  sops.secrets = {
    pocket_id_encryption_key = {};
    pocket_id_static_api_key = {};
  };

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://id.hooba.be";
      TRUST_PROXY = true;
    };
    # Passed as *_FILE credentials; values must have no trailing newline.
    credentials = {
      ENCRYPTION_KEY = config.sops.secrets.pocket_id_encryption_key.path;
      STATIC_API_KEY = config.sops.secrets.pocket_id_static_api_key.path;
    };
  };

  # Vhost here so disabling Pocket ID drops the proxy.
  services.caddy.virtualHosts."id.hooba.be" = {
    useACMEHost = "hooba.be";
    extraConfig = "reverse_proxy 127.0.0.1:1411";
  };

  # Resolve locally; don't depend on AdGuard.
  networking.hosts."127.0.0.1" = ["id.hooba.be"];
}
