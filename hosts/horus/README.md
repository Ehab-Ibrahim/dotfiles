# horus

Home server: Lenovo Y50-70 laptop, headless with the lid closed, wired Ethernet.

## Configuration

| Area | Setting |
|---|---|
| Layout | `configuration.nix` is core host setup (including TLP/lid and SSH); services live in `services/` |
| Disk (`disko.nix`) | 1G EFI at `/boot`; LVM `pool`: root 50G, swap 8G, `/srv` 800G, ~72G free to grow either (`sudo lvextend -r -L +20G /dev/pool/srv`) |
| Power (TLP) | runtime PM on, except the Realtek NIC (`r8169`); Wi-Fi and Bluetooth off; battery conservation mode (~60%) |
| Headless | lid ignored, console blanks after 60s |
| Users | `eibrahim` (wheel, fish) with an initial password `changeme`; root has no password |
| SSH | keys only; `IPQoS cs0 cs0` (the Wi-Fi AP stalled marked packets); keepalives every 30s |
| Nix | weekly GC of generations older than 14 days; `@wheel` trusted, so deploys from the PC work |
| Home-manager | NixOS module, `home.nix`; dotfiles copied into the store (`dotfiles.mutable = false`), no repo clone needed |

## Services

| Service | Setting |
|---|---|
| Tailscale (`services/tailscale.nix`) | remote access; tailnet devices reach every port. After a reinstall: `sudo tailscale up` |
| AdGuard Home (`services/adguard.nix`) | DNS resolver and ad-blocker; web UI proxied by Caddy; local name resolution and settings configured in the UI; stored in `/var/lib/AdGuardHome` (back it up before a reinstall) |
| Caddy (`services/caddy.nix`) | Reverse proxy and TLS/certificate handling for local services; each service owns its vhost (see Certificates below) |

## Install (wipes the SSD)

nixos-anywhere's kexec installer (kernel 7.0) hung the NIC, so install from a
NixOS minimal ISO on USB instead:

1. Boot the USB, run `sudo passwd root`, note the IP.
2. From this repo on the PC:
   ```
   ssh-copy-id -f -o PubkeyAuthentication=no root@<ip>
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#horus --phases disko,install --target-host root@<ip>
   ```
3. Remove the USB, reboot, then `ssh-keygen -R 192.168.0.4`, `ssh horus`, `passwd`.

## Certificates

Caddy gets a wildcard `*.hooba.be` certificate from Let's Encrypt via DNS-01.
The zone must be managed by Infomaniak; no A record is needed, because LAN
clients resolve through AdGuard.

The first deploy needs the Infomaniak API token (`dns:read` and `dns:write`) on
the host; without it, Caddy serves the self-signed placeholder certificate:

```
sudo touch /var/lib/acme-token
sudo chmod 600 /var/lib/acme-token
sudoedit /var/lib/acme-token    # the token alone
```

Caddy starts after `acme-hooba.be.service` and is reloaded on renewal. Nothing
is exposed to the internet: lego proves ownership with a temporary
`_acme-challenge.hooba.be` TXT record.

## Deploy

From the PC: `nixos-deploy horus`, which builds the host as a GC root and runs

```
nixos-rebuild switch --flake .#horus --target-host horus --sudo --ask-sudo-password --use-substitutes
```

Extra arguments are passed through to `nixos-rebuild`.

If the NIC hangs (link up, no traffic), from the keyboard:
`sudo modprobe -r r8169 && sudo modprobe r8169`. Avoid `sudo lspci -vv`.
