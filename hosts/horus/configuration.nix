# NixOS config for the `horus` home server (Lenovo Y50-70, i7-4710HQ).
# See ./README.md for the reasoning.
# Partitions come from disko.nix. hardware-configuration.nix is generated at
# install time (see ./README.md); until then the config evaluates without it.
{
  lib,
  pkgs,
  ...
}: {
  imports =
    [ ./opencloud.nix ]
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.loader.systemd-boot.enable = true;
  # Old generations stay on disk until GC, but drop out of the boot menu
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  # Blank the console (the laptop panel) after 60s
  boot.kernelParams = ["consoleblank=60"];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  networking.hostName = "horus";
  networking.networkmanager.enable = true;

  # Headless: the lid stays closed
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  services.tlp = {
    enable = true;
    settings = {
      # Let idle PCI devices sleep on AC (TLP's AC default is "on")
      RUNTIME_PM_ON_AC = "auto";
      # TLP's default list plus the Realtek NIC (r8169), which can hang
      RUNTIME_PM_DRIVER_DENYLIST = "mei_me nouveau radeon xhci_hcd r8169";
      DEVICES_TO_DISABLE_ON_STARTUP = "wifi bluetooth";
      # ideapad conservation mode: hold the battery at ~60%
      STOP_CHARGE_THRESH_BAT0 = 1;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      # Disable QoS marking - makes ssh more reliable
      IPQoS = "cs0 cs0";
      ClientAliveInterval = 30;
      ClientAliveCountMax = 3;
      # Keys only; the password below is for the console and sudo
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Images, containers and volumes go on the big /srv volume, not root
  virtualisation.docker = {
    enable = true;
    daemon.settings.data-root = "/srv/docker";
  };
  systemd.services.docker.unitConfig.RequiresMountsFor = "/srv/docker";

  # Adguard home for DNS ad-blocking
  services.adguardhome = {
    enable = true;
    openFirewall = true; # web UI port
  };

  # Reverse proxy: <service>.horus (AdGuard rewrite *.horus) to local ports
  services.caddy = {
    enable = true;
    virtualHosts."http://adguard.horus".extraConfig = "reverse_proxy 127.0.0.1:3000";
  };

  networking.firewall = {
    allowedTCPPorts = [53 80];
    allowedUDPPorts = [53];
    # Devices on the tailnet reach every service, like on the LAN
    trustedInterfaces = ["tailscale0"];
  };

  # Remote access; log in once with `sudo tailscale up`
  services.tailscale = {
    enable = true;
    openFirewall = true; # direct (peer-to-peer) connections
  };

  home-manager = {
    # Use the system's nixpkgs; install packages into /etc/profiles/per-user
    useGlobalPkgs = true;
    useUserPackages = true;
    # Move files that are in the way (e.g. ones apps created) to *.backup
    backupFileExtension = "backup";
    users.eibrahim = import ./home.nix;
  };

  programs.fish.enable = true;
  users.users.eibrahim = {
    isNormalUser = true;
    # docker group membership is root-equivalent
    extraGroups = ["wheel" "networkmanager" "docker"];
    shell = pkgs.fish;
    # Only applies when the user is created; change it with `passwd` on first login
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITEvKX1sMTqT0MZOYobI2AUV9FkJ48hDI4ow+kfRRA3"
    ];
  };

  # Diagnostics. Don't run `lspci -vv` as root: reading the NIC's VPD likely
  # hung it once
  environment.systemPackages = [
    pkgs.powertop
    pkgs.ethtool
    pkgs.pciutils
    pkgs.usbutils
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  # Accept paths copied by deploys from the PC (wheel can sudo anyway)
  nix.settings.trusted-users = ["@wheel"];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # Set to the NixOS release you install with, then never change it
  system.stateVersion = "26.11";
}
