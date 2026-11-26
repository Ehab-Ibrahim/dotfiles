# Beszel + Pocket ID SSO; Beszel's own password login is disabled.
# Beszel (PocketBase) needs a client secret: each hub start gets a fresh one
# from Pocket ID and sets it through Beszel's API.
{
  config,
  pkgs,
  ...
}: let
  pocketId = config.services.pocket-id.settings;
  hub = config.services.beszel.hub;
  issuer = pocketId.APP_URL;
  clientId = "beszel";
  secretFile = "/run/beszel-hub/oidc-secret";

  # Only members of this Pocket ID group may sign in.
  provision = pkgs.writeText "pocketid-beszel.json" (builtins.toJSON {
    groups.beszel_users = "Beszel Users";
    clients.${clientId} = {
      name = "Beszel";
      callbacks = ["${hub.environment.APP_URL}/api/oauth2-redirect"];
      inherit secretFile;
    };
  });

  # PATCH body for Beszel's users collection; the secret is filled in at runtime.
  oauth2 = pkgs.writeText "beszel-oauth2.json" (builtins.toJSON {
    oauth2 = {
      enabled = true;
      providers = [
        {
          name = "oidc";
          displayName = "Pocket ID";
          inherit clientId;
          authURL = "${issuer}/authorize";
          tokenURL = "${issuer}/api/oidc/token";
          userInfoURL = "${issuer}/api/oidc/userinfo";
          pkce = true;
        }
      ];
    };
  });

  # Collection settings need a superuser: (re)set one with a throwaway password.
  # Having a second superuser also closes Beszel's first-account setup page.
  setup = pkgs.writers.writeNu "beszel-oidc" ''
    let url = "http://${hub.host}:${toString hub.port}"
    let email = "provision@beszel.local"
    let password = random chars --length 32

    # Pocket ID group and client; writes a fresh client secret to ${secretFile}.
    ^${pkgs.python3Minimal.interpreter} ${../pocket-id/provision.py} ${provision}

    ^${hub.package}/bin/beszel-hub superuser upsert $email $password

    # Wait up to 30s for the hub to answer.
    for attempt in 1..30 {
      try { http get $"($url)/api/health"; break } catch { sleep 1sec }
    }

    let login = (
      http post $"($url)/api/collections/_superusers/auth-with-password"
        --content-type application/json
        {identity: $email, password: $password}
    )

    let settings = (
      open ${oauth2}
        | upsert oauth2.providers.0.clientSecret (open --raw ${secretFile})
    )
    (
      http patch $"($url)/api/collections/users" $settings
        --content-type application/json
        --headers {Authorization: $login.token}
    ) | ignore
  '';
in {
  services.beszel.hub.environment = {
    DISABLE_PASSWORD_AUTH = "true";
    # Create Beszel users on first Pocket ID login.
    USER_CREATION = "true";
  };

  systemd.services.beszel-hub = {
    after = ["pocket-id.service"];
    wants = ["pocket-id.service"];
    environment.POCKET_ID_URL = "http://${pocketId.HOST}:${toString pocketId.PORT}";
    serviceConfig = {
      LoadCredential = "POCKET_KEY:${config.sops.secrets.pocket_id_static_api_key.path}";
      # "-": if Pocket ID is down, keep running with the previous login config.
      ExecStartPost = ["-${setup}"];
    };
  };
}
