##################################
#                                #
#      Cala Web (hub)            #
#      Hetzner Cloud CPX02       #
#      (x86_64, 1 GB RAM)        #
#                                #
#  Minimal public web server:    #
#  Caddy serves every site in    #
#  ./sites with automatic HTTPS. #
#                                #
##################################
#
# Deploy from devbox at /etc/nixos. The box is x86_64, so devbox evaluates AND
# builds, then copies the closure over. Never build on the box itself: 1 GB of
# RAM can't run a nix build, and the 20 GB disk has no room for one.
#
#   First install (a new server, with the cala-m-os installer):
#     1. Create the server as a CPX02 with no Volumes attached. CPX boots UEFI,
#        which this layout needs (the CX line is legacy BIOS: don't use it).
#     2. Point every site's domain at its IPv4 BEFORE installing: an A record,
#        DNS-only (grey cloud on Cloudflare; proxied breaks the ACME
#        challenges). Check it with `dig +short <domain> @1.1.1.1`.
#     3. Rescale the powered-off server UP for the install: "CPU and RAM only"
#        to a CPX with 4 GB or more (this leaves the disk at 20 GB, so it can
#        scale back down). The installer runs from RAM and evaluates and
#        fetches the flake on the box; 1 GB can't hold that.
#     4. Boot the installer ISO. Hetzner mounts custom ISOs only through a
#        support ticket (direct-download link, "x86"), and an ISO is private to
#        its project; then Server -> ISO Images -> mount, and reboot. Work in
#        the web console. cala-web has no private inputs, so the plain ISO is
#        enough (no PAT needed). If the TUI finds no network, pick "Hetzner
#        Cloud: set the static address" in its no-network menu.
#     5. In cala-installer pick cala-web. HETZNER-CPX can't set wipeAllDisks,
#        so the TUI runs disko itself: check that the device it lists is
#        /dev/sda (the only disk), type `yes`, and the install continues. By
#        hand, from "Drop to a shell":
#          sudo -i
#          disko --mode destroy,format,mount --flake github:CalamooseLabs/cala-m-os#cala-web
#          INSTALL_SKIP_DISKO=1 install-cala-m-os cala-web
#        The installer builds the default branch: merge this host first.
#     6. Unmount the ISO, reboot, and let the box come up on the full
#        configuration (on DHCP: calamoose.hetznerCloud, both addresses null).
#        Then power off, rescale back down to CPX02 (CPU and RAM only), and
#        power on. From here on nothing builds on the box.
#     7. If a record was added after the box came up, run
#        `sudo systemctl restart caddy`. That skips the remaining ACME retry
#        backoff, which can reach hours. Check with `curl -sSI https://<domain>`.
#        Caddy logs only errors, so a successful issuance prints nothing.
#     8. IPv6: copy the /64 from the Cloud Console into
#        calamoose.hetznerCloud.ipv6Address below, deploy, confirm `curl -6`
#        works from the box, and only THEN publish AAAA records — Let's Encrypt
#        validates over IPv6 first, so an AAAA record without working IPv6
#        breaks certificate issuance. (ipv4Address pins IPv4 too, if DHCP is to
#        be off entirely.)
#   Without the ISO: steps 1-3, then Rescue (linux64, with an SSH key; reset
#   into it, `ls /sys/firmware/efi`, `lsblk`) and from devbox
#     nix run github:nix-community/nixos-anywhere -- --flake .#cala-web \
#       --target-host root@<ipv4> --build-on local
#   (add `--kexec-extra-flags -c` if kexec fails with "Address not available"),
#   then `ssh-keygen -R <ipv4>` and steps 6-8.
#   Updates (built on devbox, activated on the box):
#     nixos-rebuild switch --flake .#cala-web --target-host hub@<host> --sudo
#   Reinstall in place: rescale up (step 3) first — at 1 GB `cala-reinstall`
#   refuses, its image needs ~2 GB — then `sudo cala-reinstall --no-token` (no
#   private inputs) and steps 5-6 in the installer it kexecs into.
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
  machine_uuid = "HETZNER-CPX";
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
    # The HETZNER-CPX machine's hetzner-cloud module (and its options) exists
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

  networking.hostName = "cala-web";

  # ---- Headless ------------------------------------------------------------
  # greetd pulls in the whole graphical-desktop stack (pipewire, mesa, fonts,
  # graphical.target). Turn it off and let the VNC console land in a plain
  # autologin TTY. That console is the break-glass path when networking is
  # broken, and it sits behind the Hetzner account, which could rescue-boot and
  # mount this disk anyway. (The visible boot menu and no Plymouth come from the
  # hetzner-cloud machine module.)
  services.greetd.enable = lib.mkForce false;
  services.getty.autologinUser = cala-m-os.globals.defaultUser;

  # 1 GB of RAM: keep /tmp on disk, not in RAM.
  boot.tmp.useTmpfs = lib.mkForce false;
  boot.tmp.cleanOnBoot = true;

  # Internet-facing: keys only, and no PAM keyboard-interactive path either.
  services.openssh.settings.KbdInteractiveAuthentication = false;
  # profiles/minimal.nix turns logrotate off, but it is the only thing that
  # rotates /var/log/btmp. Every failed SSH probe from the internet appends to it.
  services.logrotate.enable = true;
}
