# Beszel + Pocket ID SSO; password login is disabled. PocketBase needs a client
# secret: a root unit fetches it, so the hub never sees the Pocket ID API key.
{
  config,
  lib,
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

  # Logs in with USER_EMAIL/USER_PASSWORD from sops (superuser upserted below).
  setup = pkgs.writers.writeNu "beszel-oidc" ''
    let url = "http://${hub.host}:${toString hub.port}"
    let secret = open --raw ($env.CREDENTIALS_DIRECTORY | path join OIDC_SECRET)

    # Wait up to 30s for the hub.
    for attempt in 1..30 {
      try { http get $"($url)/api/health"; break } catch { sleep 1sec }
    }

    let login = (
      http post $"($url)/api/collections/_superusers/auth-with-password"
        --content-type application/json
        {identity: $env.USER_EMAIL, password: $env.USER_PASSWORD}
    )

    let settings = open ${oauth2} | upsert oauth2.providers.0.clientSecret $secret
    (
      http patch $"($url)/api/collections/users" $settings
        --content-type application/json
        --headers {Authorization: $login.token}
    ) | ignore
  '';
in {
  sops.secrets.beszel_bootstrap = {};

  services.beszel.hub = {
    environment = {
      DISABLE_PASSWORD_AUTH = "true";
      # Create users on first Pocket ID login.
      USER_CREATION = "true";
      # Same-window redirect: the automatic login popup gets blocked.
      OAUTH_DISABLE_POPUP = "true";
    };
    environmentFile = config.sops.secrets.beszel_bootstrap.path;
  };

  # Only this group may sign in.
  services.pocket-id.provision.beszel = {
    groups.beszel_users = "Beszel Users";
    clients.${clientId} = {
      name = "Beszel";
      # The redirect flow returns to the app root.
      callbacks = ["${hub.environment.APP_URL}/"];
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
    # After migrations; syncs the superuser with sops.
    ExecStartPre = lib.mkAfter [
      "${hub.package}/bin/beszel-hub superuser upsert \${USER_EMAIL} \${USER_PASSWORD}"
    ];
    # "-": on failure, keep the previous login config.
    ExecStartPost = ["-${setup}"];
  };
}
