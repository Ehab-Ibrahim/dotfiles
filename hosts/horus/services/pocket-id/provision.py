#!/usr/bin/env python3
"""Ensure Pocket ID groups and OIDC clients from <provision.json> exist.

Spec: {"groups": {"<name>": "<friendly name>"},
       "clients": {"<id>": {"name", "callbacks", "logout"?, "secretFile"?}}}
Creates missing groups/clients and reapplies listed settings (other UI edits
are kept), restricting sign-in to those groups. Clients are public PKCE unless
secretFile is set, which keeps a stable secret out of the Nix store.
"""

import json
import os
import secrets
import sys
import urllib.error
import urllib.request
from pathlib import Path

BASE_URL = os.environ["POCKET_ID_URL"]
API_KEY = Path(os.environ["CREDENTIALS_DIRECTORY"], "POCKET_KEY").read_text().strip()

# Pocket ID defaults pagination to 20.
PAGE = "pagination[limit]=100"


def api(method, path, data=None):
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(
        BASE_URL + path,
        data=body,
        method=method,
        headers={"X-API-KEY": API_KEY, "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            raw = resp.read()
    except urllib.error.HTTPError as exc:
        sys.exit(f"{method} {path}: HTTP {exc.code}: {exc.read().decode()}")
    return json.loads(raw) if raw else {}


def main():
    spec = json.loads(Path(sys.argv[1]).read_text())

    groups = api("GET", f"/api/user-groups?{PAGE}")["data"]
    existing = {g["name"]: g["id"] for g in groups}
    for name, friendly in spec["groups"].items():
        if name not in existing:
            body = {"name": name, "friendlyName": friendly}
            existing[name] = api("POST", "/api/user-groups", body)["id"]
    group_ids = [existing[name] for name in spec["groups"]]

    existing = {c["id"]: c for c in api("GET", f"/api/oidc/clients?{PAGE}")["data"]}
    for cid, client in spec["clients"].items():
        secret_file = client.get("secretFile")
        settings = {
            "name": client["name"],
            "callbackURLs": client["callbacks"],
            "logoutCallbackURLs": client.get("logout", []),
            "isPublic": secret_file is None,
            "pkceEnabled": True,
            "skipConsent": True,
            "isGroupRestricted": True,
        }
        if cid in existing:
            # PUT replaces the whole client: keep what was changed by hand.
            api("PUT", f"/api/oidc/clients/{cid}", {**existing[cid], **settings})
        else:
            api("POST", "/api/oidc/clients", {"id": cid, **settings})
        api(
            "PUT",
            f"/api/oidc/clients/{cid}/allowed-user-groups",
            {"userGroupIds": group_ids},
        )

        if secret_file:
            # Stable value so reboots can't desync Pocket ID and the service.
            file = Path(secret_file)
            secret = (
                file.read_text().strip() if file.exists() else secrets.token_urlsafe(32)
            )
            file.write_text(secret)
            path = f"/api/oidc/clients/{cid}/secrets"
            for old in api("GET", path) or []:
                api("DELETE", f"{path}/{old['id']}")
            api("POST", path, {"secret": secret})

    print("Pocket ID provisioning complete")


if __name__ == "__main__":
    main()
