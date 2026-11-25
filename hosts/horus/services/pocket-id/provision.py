#!/usr/bin/env python3
"""Ensure Pocket ID groups and OIDC clients from <provision.json> exist.

Spec: {"groups": [{"name", "friendlyName"}],
       "clients": {"<id>": {"name", "callbacks", "logout"?}}}
Creates missing groups and public PKCE clients (consent skipped), restricted to
these groups; keeps existing clients' callbacks and allowed groups in sync.
"""

import json
import os
import sys
import time
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
    except urllib.error.URLError as exc:
        sys.exit(f"{method} {path}: {exc.reason}")
    return json.loads(raw) if raw else {}


def wait():
    for _ in range(30):
        try:
            urllib.request.urlopen(BASE_URL + "/healthz", timeout=2).close()
            return
        except OSError:
            time.sleep(1)
    sys.exit("Pocket ID did not become healthy within 30s")


def main():
    spec = json.loads(Path(sys.argv[1]).read_text())
    wait()

    existing = {g["name"]: g for g in api("GET", f"/api/user-groups?{PAGE}")["data"]}
    group_ids = []
    for group in spec["groups"]:
        found = existing.get(group["name"]) or api(
            "POST",
            "/api/user-groups",
            {"name": group["name"], "friendlyName": group["friendlyName"]},
        )
        group_ids.append(found["id"])

    existing = {c["id"]: c for c in api("GET", f"/api/oidc/clients?{PAGE}")["data"]}
    for cid, client in spec["clients"].items():
        callbacks = client["callbacks"]
        logout = client.get("logout", [])
        found = existing.get(cid)
        if not found:
            api(
                "POST",
                "/api/oidc/clients",
                {
                    "id": cid,
                    "name": client["name"],
                    "callbackURLs": callbacks,
                    "logoutCallbackURLs": logout,
                    "isPublic": True,
                    "pkceEnabled": True,
                    "skipConsent": True,
                },
            )
        else:
            # PUT replaces the whole client, so round-trip the listed values.
            found.update(
                name=client["name"],
                callbackURLs=callbacks,
                logoutCallbackURLs=logout,
            )
            api("PUT", f"/api/oidc/clients/{cid}", found)
        api(
            "PUT",
            f"/api/oidc/clients/{cid}/allowed-user-groups",
            {"userGroupIds": group_ids},
        )

    print("Pocket ID provisioning complete")


if __name__ == "__main__":
    main()
