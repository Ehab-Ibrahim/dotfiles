# horus

Home server: Lenovo Y50-70 laptop, headless with the lid closed, wired Ethernet.

## Settings

| Area | Setting |
|---|---|
| Disk (`disko.nix`) | 1G EFI at `/boot`; LVM `pool`: root 50G, swap 8G, `/srv` 800G, ~72G free to grow either (`sudo lvextend -r -L +20G /dev/pool/srv`) |
| Power (TLP) | runtime PM on, except the Realtek NIC (`r8169`); Wi-Fi and Bluetooth off; battery conservation mode (~60%) |
| Headless | lid ignored, console blanks after 60s |
| SSH | keys only; `IPQoS cs0 cs0` (the Wi-Fi AP stalled marked packets); keepalives every 30s |
| Users | `eibrahim` (wheel, fish) with an initial password `changeme`; root has no password |
| Tailscale | remote access; tailnet devices reach every port. After a reinstall: `sudo tailscale up` |
| AdGuard Home | DNS on port 53, web UI on port 3000; configured in the UI, stored in `/var/lib/AdGuardHome` (back it up before a reinstall) |
| Caddy | Reverse proxy on port 80; `http://adguard.horus` -> `localhost:3000`, backed by AdGuard DNS rewrites |
| Nix | weekly GC of generations older than 14 days; `@wheel` trusted, so deploys from the PC work |
| Home-manager | NixOS module, `home.nix`; dotfiles copied into the store (`dotfiles.mutable = false`), no repo clone needed |

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

## Deploy

From the PC: `deploy-horus`, which runs

```
nixos-rebuild switch --flake .#horus --target-host horus --sudo --ask-sudo-password --use-substitutes
```

If the NIC hangs (link up, no traffic), from the keyboard:
`sudo modprobe -r r8169 && sudo modprobe r8169`. Avoid `sudo lspci -vv`.
