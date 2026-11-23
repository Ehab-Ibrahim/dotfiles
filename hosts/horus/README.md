# horus

Headless home server (Lenovo Y50-70, wired Ethernet).

## Layout

- `configuration.nix` — core host config; imports modules from `services/`.
- `disko.nix` — disk layout; `hardware-configuration.nix` is install-generated.
- `services/` — one module per service; each owns its Caddy vhost.
- `secrets.yaml` — sops-encrypted secrets.

## Services

Tailscale, AdGuard Home, Caddy, Pocket ID (passkey IdP at `id.hooba.be`) and
OpenCloud (`cloud.hooba.be`, state in `/srv/opencloud`). The optional
`services/pocketid-opencloud.nix` makes OpenCloud use Pocket ID as its OIDC
provider; omit it to keep the built-in IdP. The choice is made on first deploy —
switching later requires re-initialising OpenCloud.

## Secrets

`secrets.yaml` holds the Infomaniak token and Pocket ID's `ENCRYPTION_KEY` and
`STATIC_API_KEY`. Encrypted to the PC and host keys, decrypted at activation by
sops-nix into `/run/secrets`. Edit with `sops hosts/horus/secrets.yaml`.

## Install

1. Boot a NixOS minimal ISO, `sudo passwd root`, note the IP.
2. Stage the host key:
   ```
   umask 077
   mkdir -p ~/horus-extra/var/lib/sops-nix
   rbw get ssh-sops-horus -f private_key > ~/horus-extra/var/lib/sops-nix/sops_ed25519_key
   ```
3. From the PC:
   ```
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#horus --phases disko,install --target-host root@<ip> \
     --extra-files ~/horus-extra
   ```
4. Reboot, log in, set the password.

TLS uses a wildcard `*.hooba.be` cert via DNS-01 (token from sops). After a fresh
install: `sudo tailscale up`, restore AdGuard's state, sign up the initial Pocket
ID admin and enroll a passkey.

## Deploy

`nixos-deploy horus`, or:

```
nixos-rebuild switch --flake .#horus --target-host horus --sudo --ask-sudo-password --use-substitutes
```
