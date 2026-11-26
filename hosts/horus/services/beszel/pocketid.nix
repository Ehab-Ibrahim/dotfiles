# Beszel + Pocket ID SSO; password login is disabled. PocketBase needs a client
# secret: a root unit fetches it, so the hub never sees the Pocket ID API key.
{
  config,
  pkgs,
  ...
}: let
  hub = config.services.beszel.hub;
  issuer = config.services.pocket-id.settings.APP_URL;
  clientId = "beszel";
  # In the state dir of pocket-id-beszel-provision (../pocket-id/provision.nix).
  secretFile = "/var/lib/pocket-id-beszel/client-secret";

  # PATCH body for Beszel's users collection; secret added at runtime.
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

  # The API needs a superuser: upsert one with a throwaway password.
  # A second superuser also closes Beszel's first-account setup page.
  setup = pkgs.writers.writeNu "beszel-oidc" ''
    let url = "http://${hub.host}:${toString hub.port}"
    let email = "provision@beszel.local"
    let password = random chars --length 32
    let secret = open --raw ($env.CREDENTIALS_DIRECTORY | path join OIDC_SECRET)

    ^${hub.package}/bin/beszel-hub superuser upsert $email $password

    # Wait up to 30s for the hub.
    for attempt in 1..30 {
      try { http get $"($url)/api/health"; break } catch { sleep 1sec }
    }

    let login = (
      http post $"($url)/api/collections/_superusers/auth-with-password"
        --content-type application/json
        {identity: $email, password: $password}
    )

    let settings = open ${oauth2} | upsert oauth2.providers.0.clientSecret $secret
    (
      http patch $"($url)/api/collections/users" $settings
        --content-type application/json
        --headers {Authorization: $login.token}
    ) | ignore
  '';
in {
  services.beszel.hub.environment = {
    DISABLE_PASSWORD_AUTH = "true";
    # Create users on first Pocket ID login.
    USER_CREATION = "true";
  };

  # Only this group may sign in.
  services.pocket-id.provision.beszel = {
    groups.beszel_users = "Beszel Users";
    clients.${clientId} = {
      name = "Beszel";
      callbacks = ["${hub.environment.APP_URL}/api/oauth2-redirect"];
      inherit secretFile;
    };
  };

  # Before the hub, which can't start until this succeeds once.
  systemd.services.pocket-id-beszel-provision = {
    before = ["beszel-hub.service"];
    wantedBy = ["beszel-hub.service"];
  };

  systemd.services.beszel-hub.serviceConfig = {
    # systemd copies the root-only file for the hub.
    LoadCredential = "OIDC_SECRET:${secretFile}";
    # "-": on failure, keep the previous login config.
    ExecStartPost = ["-${setup}"];
  };
}
