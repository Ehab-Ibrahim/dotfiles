# Optional: OpenCloud logs in through Pocket ID. Omit from imports to keep OpenCloud's
# built-in IdP; decide before OpenCloud's first start, switching later means
# re-initialising it. Users need one of the groups below; the group sets their role.
{
  config,
  lib,
  pkgs,
  ...
}: let
  pocketId = config.services.pocket-id.settings;
  issuer = pocketId.APP_URL;
  cloud = config.services.opencloud.url;

  # Group names are OpenCloud's built-in role claim values, so OpenCloud maps the
  # `groups` claim to roles itself (highest role wins).
  groups = [
    {
      name = "opencloudAdmin";
      friendlyName = "OpenCloud Admins";
    }
    {
      name = "opencloudSpaceAdmin";
      friendlyName = "OpenCloud Space Admins";
    }
    {
      name = "opencloudUser";
      friendlyName = "OpenCloud Users";
    }
    {
      name = "opencloudGuest";
      friendlyName = "OpenCloud Guests";
    }
  ];

  # OIDC clients, keyed by the client ID each OpenCloud app expects.
  # `logout` is optional (logout callback URLs, empty by default).
  clients = {
    web = {
      name = "OpenCloud Web";
      callbacks = [
        "${cloud}/"
        "${cloud}/oidc-callback.html"
        "${cloud}/oidc-silent-redirect.html"
      ];
      logout = ["${cloud}/"];
    };
    OpenCloudDesktop = {
      name = "OpenCloud Desktop";
      callbacks = ["http://127.0.0.1" "http://localhost"];
    };
    OpenCloudAndroid = {
      name = "OpenCloud Android";
      callbacks = ["oc://android.opencloud.eu"];
    };
    OpenCloudIOS = {
      name = "OpenCloud iOS";
      callbacks = ["oc://ios.opencloud.eu" "oc.ios://ios.opencloud.eu"];
    };
  };

  # Input for ./pocketid-opencloud.py.
  provision = pkgs.writeText "pocketid-opencloud.json" (builtins.toJSON {inherit groups clients;});
in {
  # External-OIDC settings (per the Pocket ID guide); `web` is a client ID above.
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
    PROXY_ROLE_ASSIGNMENT_OIDC_CLAIM = "groups";
    GRAPH_ASSIGN_DEFAULT_USER_ROLE = "false";
    GRAPH_USERNAME_MATCH = "none";
    PROXY_CSP_CONFIG_FILE_LOCATION = "/etc/opencloud/csp.yaml";
  };

  # OpenCloud merges this into its built-in CSP.
  services.opencloud.settings.csp.directives."connect-src" = [
    issuer
    "wss://${lib.removePrefix "https://" issuer}"
  ];

  # The script and its data are part of the unit, so changing either re-runs it on switch.
  systemd.services.pocket-id-opencloud-provision = {
    description = "Provision OpenCloud groups and OIDC clients in Pocket ID";
    after = ["pocket-id.service"];
    wants = ["pocket-id.service"];
    wantedBy = ["multi-user.target"];

    environment.POCKET_ID_URL = "http://${pocketId.HOST}:${toString pocketId.PORT}";

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.python3Minimal.interpreter} ${./pocketid-opencloud.py} ${provision}";
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
