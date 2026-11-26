# Pocket ID groups and clients for other services: each entry of
# services.pocket-id.provision gets a root unit pocket-id-<name>-provision that
# runs ./provision.py once per boot. Client secrets go to /var/lib/pocket-id-<name>.
{
  config,
  lib,
  pkgs,
  ...
}: let
  pocketId = config.services.pocket-id.settings;

  provisionUnit = name: spec:
    lib.nameValuePair "pocket-id-${name}-provision" {
      description = "Provision Pocket ID groups and clients for ${name}";
      after = ["pocket-id.service"];
      wants = ["pocket-id.service"];
      wantedBy = ["multi-user.target"];

      environment.POCKET_ID_URL = "http://${pocketId.HOST}:${toString pocketId.PORT}";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          specFile = pkgs.writeText "pocket-id-${name}.json" (builtins.toJSON spec);
        in "${pkgs.python3Minimal.interpreter} ${./provision.py} ${specFile}";
        LoadCredential = "POCKET_KEY:${config.sops.secrets.pocket_id_static_api_key.path}";
        StateDirectory = "pocket-id-${name}";
        StateDirectoryMode = "0700";
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };
in {
  options.services.pocket-id.provision = lib.mkOption {
    type = with lib.types; attrsOf attrs;
    default = {};
    description = "Groups and clients per service; format in ./provision.py.";
  };

  config.systemd.services = lib.mapAttrs' provisionUnit config.services.pocket-id.provision;
}
