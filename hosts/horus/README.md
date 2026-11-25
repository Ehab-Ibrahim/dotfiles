# horus

Headless home server: Lenovo Y50-70 laptop, lid closed, wired Ethernet.

## Layout

- `configuration.nix`: host setup (power, SSH, users, Nix); imports `services/`.
- `services/`: one module per service; a service with extras (e.g. Pocket ID
  login) is a folder whose `default.nix` imports them.
- `disko.nix`: disk layout. LVM keeps ~72G free to grow a volume, e.g.
  `sudo lvextend -r -L +20G /dev/pool/srv`.
- `secrets.yaml`: sops-encrypted secrets.
- `hardware-configuration.nix`: generated at install.

## Services

Each module in `services/` owns everything for its service, so dropping its
import removes it completely:

- its Caddy vhost `<name>.hooba.be` (`useACMEHost = "hooba.be"`) and a
  `networking.hosts` entry, so horus resolves the name without AdGuard;
- its secrets (`sops.secrets.<name>`);
- a header comment with its URL, where its state lives and what to do after a
  reinstall. Back up those paths before reinstalling.

Large data goes on `/srv`, a separate volume.

## Secrets

sops-nix decrypts `secrets.yaml` at activation into root-only files under
`/run/secrets`; modules use `config.sops.secrets.<name>.path`. Recipients are in
`/.sops.yaml`: the PC, and a horus decryption key that grants no login, stored
in rbw as `ssh-sops-horus` and staged at install. On the PC, sops reads keys
from rbw (`SOPS_AGE_SSH_PRIVATE_KEY_CMD` in `home-manager/services/rbw.nix`):

- edit: `sops hosts/horus/secrets.yaml`
- after changing recipients: `sops updatekeys -y hosts/horus/secrets.yaml`

## TLS

Caddy holds one wildcard `*.hooba.be` Let's Encrypt cert, obtained by DNS-01
with an Infomaniak API token (`dns:read`, `dns:write`) from sops. Without the
token it serves a self-signed placeholder. Nothing is exposed to the internet;
LAN clients resolve `*.hooba.be` through AdGuard rewrites.

## Install (wipes the SSD)

nixos-anywhere's kexec installer hung the NIC, so boot a NixOS minimal ISO from
USB instead.

1. Boot the USB, run `sudo passwd root`, note the IP.
2. Stage the sops key (`--extra-files` copies it into the new system):
   ```
   umask 077
   mkdir -p ~/horus-extra/var/lib/sops-nix
   rbw get ssh-sops-horus -f private_key > ~/horus-extra/var/lib/sops-nix/sops_ed25519_key
   ```
3. From this repo on the PC:
   ```
   ssh-copy-id -f -o PubkeyAuthentication=no root@<ip>
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#horus --phases disko,install --target-host root@<ip> \
     --extra-files ~/horus-extra
   ```
4. Remove the USB and reboot. Then `ssh-keygen -R 192.168.0.4`, `ssh horus`,
   and replace the initial password (`changeme`) with `passwd`.
5. Do the after-reinstall steps in each service module's header.

## Deploy

From the PC: `nixos-deploy horus`. It keeps the build as a GC root, then runs
`nixos-rebuild switch --flake .#horus --target-host horus --sudo
--ask-sudo-password --use-substitutes`, passing extra arguments through.

## Troubleshooting

NIC hangs (link up, no traffic): at the keyboard, run
`sudo modprobe -r r8169 && sudo modprobe r8169`. Avoid `sudo lspci -vv`:
reading the NIC's VPD likely caused a hang.
