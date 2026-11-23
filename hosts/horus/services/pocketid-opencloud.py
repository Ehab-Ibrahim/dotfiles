#!/usr/bin/env python3
"""Provision OpenCloud groups, claims and OIDC clients in Pocket ID."""

import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import NamedTuple

BASE_URL = os.environ["POCKET_ID_URL"]
CLOUD_URL = os.environ["OPENCLOUD_URL"].rstrip("/")
API_KEY = Path(os.environ["CREDENTIALS_DIRECTORY"], "POCKET_KEY").read_text().strip()

# Pocket ID caps list pages at 100 (default 20).
PAGE = "pagination[limit]=100"


class Group(NamedTuple):
    name: str
    friendly_name: str
    role: str


class Client(NamedTuple):
    name: str
    callbacks: list[str]
    logout: tuple[str, ...] = ()


GROUPS = [
    Group("opencloud_admins", "OpenCloud Admins", "opencloudAdmin"),
    Group("opencloud_spaceadmins", "OpenCloud Space Admins", "opencloudSpaceAdmin"),
    Group("opencloud_users", "OpenCloud Users", "opencloudUser"),
    Group("opencloud_guests", "OpenCloud Guests", "opencloudGuest"),
]

CLIENTS = {
    "web": Client(
        "OpenCloud Web",
        [
            f"{CLOUD_URL}/",
            f"{CLOUD_URL}/oidc-callback.html",
            f"{CLOUD_URL}/oidc-silent-redirect.html",
        ],
        (f"{CLOUD_URL}/",),
    ),
    "OpenCloudDesktop": Client(
        "OpenCloud Desktop",
        ["http://127.0.0.1", "http://localhost"],
    ),
    "OpenCloudAndroid": Client(
        "OpenCloud Android",
        ["oc://android.opencloud.eu"],
    ),
    "OpenCloudIOS": Client(
        "OpenCloud iOS",
        ["oc://ios.opencloud.eu", "oc.ios://ios.opencloud.eu"],
    ),
}


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
    wait()

    existing = {g["name"]: g for g in api("GET", f"/api/user-groups?{PAGE}")["data"]}
    group_ids = []
    for group in GROUPS:
        found = existing.get(group.name) or api(
            "POST",
            "/api/user-groups",
            {"name": group.name, "friendlyName": group.friendly_name},
        )
        group_ids.append(found["id"])
        api(
            "PUT",
            f"/api/custom-claims/user-group/{found['id']}",
            [{"key": "opencloud_role", "value": group.role}],
        )

    existing_clients = {
        c["id"] for c in api("GET", f"/api/oidc/clients?{PAGE}")["data"]
    }
    for cid, cfg in CLIENTS.items():
        if cid not in existing_clients:
            client = {
                "id": cid,
                "name": cfg.name,
                "callbackURLs": cfg.callbacks,
                "isPublic": True,
                "pkceEnabled": True,
                "skipConsent": True,
            }
            if cfg.logout:
                client["logoutCallbackURLs"] = cfg.logout
            api("POST", "/api/oidc/clients", client)
        api(
            "PUT",
            f"/api/oidc/clients/{cid}/allowed-user-groups",
            {"userGroupIds": group_ids},
        )

    print("OpenCloud provisioning complete")


if __name__ == "__main__":
    main()
