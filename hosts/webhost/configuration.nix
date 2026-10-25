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
#     3. Enable Rescue (linux64) with an SSH key and reset the server into it
#        (enabling alone only arms it). CAX servers boot UEFI, which this
#        layout needs; confirm with `ls /sys/firmware/efi` in the rescue shell
#        (and `lsblk` that /dev/sda is the only disk), then run:
#          nix run github:nix-community/nixos-anywhere -- --flake .#webhost \
#            --target-host root@<ipv4> --build-on remote
#          ssh-keygen -R <ipv4>
#        The box comes up on DHCP (calamoose.hetznerCloud, both addresses null).
#        If the kexec step fails with "Address not available" (a kernel 7.0
#        rescue kernel), add `--kexec-extra-flags -c`.
#     4. If a record was added after the box came up, run
#        `sudo systemctl restart caddy`. That skips the remaining ACME retry
#        backoff, which can reach hours. Check with `curl -sSI https://<domain>`.
#        Caddy logs only errors, so a successful issuance prints nothing.
#     5. IPv6: copy the /64 from the Cloud Console into
#        calamoose.hetznerCloud.ipv6Address below, deploy, confirm `curl -6`
#        works from the box, and only THEN publish AAAA records — Let's Encrypt
#        validates over IPv6 first, so an AAAA record without working IPv6
#        breaks certificate issuance. (ipv4Address pins IPv4 too, if DHCP is to
#        be off entirely.)
#   Updates (--no-reexec: the box's nixos-rebuild is aarch64 and can't run here):
#     nixos-rebuild switch --no-reexec --flake .#webhost \
#       --target-host hub@<host> --build-host hub@<host> --sudo
#   Reinstall in place (no media): `sudo cala-reinstall --no-token` on the box
#   (no private inputs), then pick webhost in the installer's TUI (it runs
#   disko, which asks before wiping — this host can't set wipeAllDisks; by hand:
#   `disko --mode destroy,format,mount --flake <ref>#webhost`, then
#   `INSTALL_SKIP_DISKO=1 install-cala-m-os webhost`). The installer image is
#   the firmware-less `vm` variant, which fits the 4 GB box.
#
# Log in as `hub` with the YubiKey sk keys (users/webmaster). Each SSH
# connection needs one touch.
{
  lib,
  cala-m-os,
  modulesPath,
  initialInstallMode,
  ...
}: let
  import_users = ["webmaster"];
  machine_type = "Workstation";
  machine_uuid = "HETZNER-CAX";
in {
  calamoose.version = "1.0.0";

  # No YubiKey attached and nothing to decrypt: secrets stay off.
  calamoose.enableSecrets = false;

  imports =
    [
      (modulesPath + "/profiles/minimal.nix")

      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })

      # Caddy + every site under ./sites
      ./sites
    ]
    # The HETZNER-CAX machine's hetzner-cloud module (and its options) exists
    # only in the full config, not the minimal INITIAL_INSTALL_MODE pass.
    ++ lib.optional (!initialInstallMode) {
      # ---- Hetzner Cloud networking (machines/modules/hetzner-cloud) ----------
      # IPv4 over Hetzner's DHCP until ipv4Address is set; IPv6 only once
      # ipv6Address is (Hetzner configures IPv6 statically, nothing to fall
      # back on). See the header for the order of operations around AAAA records.
      calamoose.hetznerCloud = {
        ipv4Address = null; # e.g. "203.0.113.10"
        ipv6Address = null; # e.g. "2a01:4f8:c012:3456::1/64"
      };
    };

  networking.hostName = "webhost";

  # ---- Headless ------------------------------------------------------------
  # greetd pulls in the whole graphical-desktop stack (pipewire, mesa, fonts,
  # graphical.target). Turn it off and let the VNC console land in a plain
  # autologin TTY. That console is the break-glass path when networking is
  # broken, and it sits behind the Hetzner account, which could rescue-boot and
  # mount this disk anyway. (The visible boot menu and no Plymouth come from the
  # hetzner-cloud machine module.)
  services.greetd.enable = lib.mkForce false;
  services.getty.autologinUser = cala-m-os.globals.defaultUser;

  # Builds run on this 4 GB box (--build-host), so keep /tmp on disk, not in RAM.
  boot.tmp.useTmpfs = lib.mkForce false;
  boot.tmp.cleanOnBoot = true;

  # Internet-facing: keys only, and no PAM keyboard-interactive path either.
  services.openssh.settings.KbdInteractiveAuthentication = false;
  # profiles/minimal.nix turns logrotate off, but it is the only thing that
  # rotates /var/log/btmp. Every failed SSH probe from the internet appends to it.
  services.logrotate.enable = true;
}
