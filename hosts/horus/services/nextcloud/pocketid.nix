# Nextcloud + Pocket ID SSO via oidc_login.
# Config lives in config.php; public PKCE client, no client secret.
{
  config,
  pkgs,
  ...
}: let
  pocketId = config.services.pocket-id.settings;
  issuer = pocketId.APP_URL;
  cloud = "https://${config.services.nextcloud.hostName}";
  clientId = "nextcloud";

  # Only these Pocket ID groups may sign in; they also become Nextcloud groups.
  groups = {
    nextcloud_admins = "Nextcloud Admins";
    nextcloud_users = "Nextcloud Users";
  };

  clients.${clientId} = {
    name = "Nextcloud";
    callbacks = ["${cloud}/apps/oidc_login/oidc"];
    logout = ["${cloud}/"];
  };

  provision = pkgs.writeText "pocketid-nextcloud.json" (builtins.toJSON {inherit groups clients;});
in {
  services.nextcloud.extraApps = {
    inherit (config.services.nextcloud.package.packages.apps) oidc_login;
  };

  services.nextcloud.settings = {
    # id.hooba.be is loopback-mapped.
    allow_local_remote_servers = true;
    oidc_login_provider_url = issuer;
    oidc_login_client_id = clientId;
    oidc_login_client_secret = "";
    oidc_login_code_challenge_method = "S256";
    oidc_login_scope = "openid profile email groups";

    oidc_login_auto_redirect = true;
    oidc_login_redir_fallback = true; # fallback to local login
    oidc_login_logout_url = "${cloud}/";
    oidc_login_end_session_redirect = true;

    oidc_login_disable_registration = false; # provision new users from Pocket ID
    oidc_create_groups = true;
    oidc_login_attributes = {
      id = "preferred_username"; # keep Pocket ID usernames stable
      name = "name";
      mail = "email";
      groups = "groups";
      login_filter = "groups";
    };
    oidc_login_filter_allowed_values = builtins.attrNames groups;
  };

  systemd.services.pocket-id-nextcloud-provision = {
    description = "Provision Nextcloud's Pocket ID client and groups";
    after = ["pocket-id.service"];
    wants = ["pocket-id.service"];
    wantedBy = ["multi-user.target"];

    environment.POCKET_ID_URL = "http://${pocketId.HOST}:${toString pocketId.PORT}";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.python3Minimal.interpreter} ${../pocket-id/provision.py} ${provision}";
      LoadCredential = "POCKET_KEY:${config.sops.secrets.pocket_id_static_api_key.path}";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };
}
