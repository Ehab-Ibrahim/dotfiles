# Optional Pocket ID integration. Omit from imports to keep OpenCloud's built-in IdP.
{
  config,
  lib,
  pkgs,
  ...
}: let
  pocketId = config.services.pocket-id.settings;
  issuer = pocketId.APP_URL;
in {
  # External-OIDC settings (per the Pocket ID guide); `web` matches the script's client ID.
  services.opencloud.environment = {
    OC_EXCLUDE_RUN_SERVICES = "idp";
    OC_OIDC_ISSUER = issuer;
    PROXY_OIDC_ISSUER = issuer;
    WEB_OIDC_CLIENT_ID = "web";
    WEB_OIDC_AUTHORITY = issuer;
    WEB_OIDC_METADATA_URL = "${issuer}/.well-known/openid-configuration";
    WEB_OIDC_RESPONSE_TYPE = "code";
    WEB_OIDC_SCOPE = "openid profile email groups";
    PROXY_OIDC_REWRITE_WELLKNOWN = "true";
    PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
    PROXY_AUTOPROVISION_ACCOUNTS = "true";
    PROXY_AUTOPROVISION_CLAIM_USERNAME = "preferred_username";
    PROXY_AUTOPROVISION_CLAIM_EMAIL = "email";
    PROXY_AUTOPROVISION_CLAIM_DISPLAYNAME = "name";
    PROXY_AUTOPROVISION_CLAIM_GROUPS = "groups";
    PROXY_USER_OIDC_CLAIM = "preferred_username";
    PROXY_USER_CS3_CLAIM = "username";
    PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
    PROXY_ROLE_ASSIGNMENT_OIDC_CLAIM = "opencloud_role";
    GRAPH_ASSIGN_DEFAULT_USER_ROLE = "false";
    GRAPH_USERNAME_MATCH = "none";
    PROXY_CSP_CONFIG_FILE_LOCATION = "/etc/opencloud/csp.yaml";
  };

  # OpenCloud merges this into its built-in CSP.
  services.opencloud.settings.csp.directives."connect-src" = [
    issuer
    "wss://${lib.removePrefix "https://" issuer}"
  ];

  # Changes to the script or its environment alter the unit, so a switch re-runs it.
  systemd.services.pocket-id-opencloud-provision = {
    description = "Provision OpenCloud groups and OIDC clients in Pocket ID";
    after = ["pocket-id.service"];
    wants = ["pocket-id.service"];
    wantedBy = ["multi-user.target"];

    environment = {
      POCKET_ID_URL = "http://${pocketId.HOST}:${toString pocketId.PORT}";
      OPENCLOUD_URL = config.services.opencloud.url;
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.python3Minimal.interpreter} ${./pocketid-opencloud.py}";
      LoadCredential = "POCKET_KEY:${config.sops.secrets.pocket_id_static_api_key.path}";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  systemd.services.opencloud = {
    after = ["pocket-id-opencloud-provision.service" "caddy.service"];
    wants = ["pocket-id-opencloud-provision.service"];
  };
}
