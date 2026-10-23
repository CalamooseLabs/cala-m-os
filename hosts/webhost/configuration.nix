##################################
#                                #
#      Web Host (hub)            #
#      Hetzner Cloud CAX11       #
#      (ARM64, EU only)          #
#                                #
#  Minimal public web server:    #
#  Caddy serves every site in    #
#  ./sites with automatic HTTPS. #
#                                #
##################################
#
# Deploy from devbox at /etc/nixos. Evaluation happens on devbox, but the
# builds run ON the box: it is aarch64 and devbox can't build ARM. Nearly
# everything comes from cache.nixos.org anyway.
#
#   First install:
#     1. Create the CAX11 with no Volumes attached.
#     2. Point every site's domain at its IPv4 BEFORE installing: an A record,
#        DNS-only (grey cloud on Cloudflare; proxied breaks the ACME
#        challenges). Check it with `dig +short <domain> @1.1.1.1`.
#     3. Enable Rescue (linux64) with an SSH key, or boot any stock ARM image,
#        and then run:
#          nix run github:nix-community/nixos-anywhere -- --flake .#webhost \
#            --target-host root@<ipv4> --build-on remote
#          ssh-keygen -R <ipv4>
#     4. If a record was added after the box came up, run
#        `sudo systemctl restart caddy`. That skips the remaining ACME retry
#        backoff, which can reach hours. Check with `curl -sSI https://<domain>`.
#        Caddy logs only errors, so a successful issuance prints nothing.
#   Updates (--no-reexec: the box's nixos-rebuild is aarch64 and can't run here):
#     nixos-rebuild switch --no-reexec --flake .#webhost \
#       --target-host hub@<host> --build-host hub@<host> --sudo
#
# Log in as `hub` with the YubiKey sk keys (users/webmaster). Each SSH
# connection needs one touch.
{
  lib,
  cala-m-os,
  modulesPath,
  ...
}: let
  import_users = ["webmaster"];
  machine_type = "Workstation";
  machine_uuid = "HETZNER-CAX";

  # Hetzner Cloud gives out IPv4 over DHCP but does NOT advertise IPv6 (no
  # RA/SLAAC). The server's /64 has to be configured statically, with gateway
  # fe80::1. Once the server exists, set this to "<the /64 shown in the Hetzner
  # console>::1/64", deploy, and confirm `curl -6` works. Only THEN publish AAAA
  # records: Let's Encrypt validates over IPv6 first, so an AAAA record without
  # working IPv6 breaks certificate issuance.
  ipv6Address = null; # e.g. "2a01:4f8:c012:3456::1/64"
in {
  calamoose.version = "1.0.0";

  # No YubiKey attached and nothing to decrypt: secrets stay off.
  calamoose.enableSecrets = false;

  imports = [
    (modulesPath + "/profiles/minimal.nix")

    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })

    # Caddy + every site under ./sites
    ./sites
  ];

  networking.hostName = "webhost";

  # ---- Headless ------------------------------------------------------------
  # greetd pulls in the whole graphical-desktop stack (pipewire, mesa, fonts,
  # graphical.target). Turn it off and let the VNC console land in a plain
  # autologin TTY. That console is the break-glass path when networking is
  # broken, and it sits behind the Hetzner account, which could rescue-boot and
  # mount this disk anyway.
  services.greetd.enable = lib.mkForce false;
  services.getty.autologinUser = cala-m-os.globals.defaultUser;
  boot.plymouth.enable = lib.mkForce false;
  # Show the systemd-boot menu on the console so a bad generation can be rolled back.
  boot.loader.timeout = 3;

  # Builds run on this 4 GB box (--build-host), so keep /tmp on disk, not in RAM.
  boot.tmp.useTmpfs = lib.mkForce false;
  boot.tmp.cleanOnBoot = true;

  # Internet-facing: keys only, and no PAM keyboard-interactive path either.
  services.openssh.settings.KbdInteractiveAuthentication = false;
  # profiles/minimal.nix turns logrotate off, but it is the only thing that
  # rotates /var/log/btmp. Every failed SSH probe from the internet appends to it.
  services.logrotate.enable = true;

  # ---- Hetzner Cloud networking --------------------------------------------
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "en*"; # enp1s0 on CAX
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
      };
      address = lib.optional (ipv6Address != null) ipv6Address;
      routes = lib.optional (ipv6Address != null) {Gateway = "fe80::1";};
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
