# The installer as a RAM-only kexec image: what `cala-reinstall`
# (modules/cala-reinstall) jumps a running host into, with no USB stick or ISO.
# Same installer as ./default.nix, but netboot-style: the whole store rides in
# the initrd, so the box's disks are free for install-cala-m-os to wipe. Nothing
# is written to disk until the install runs; a hard reset before that boots the
# old system again.
#
# cala-reinstall appends a small cpio holding /cala-reinstall/ to the initrd:
#   nix-access-tokens.conf, or pat (+ vault/item/field)
#                    → GitHub token for private flake inputs (./calapat.nix)
#   authorized_keys  → extra root SSH keys (the host's own)
#   ssh/ssh_host_*   → the host's SSH host keys, so its fingerprint is unchanged
#   network          → static addresses/gateways/DNS to restore (DHCP needs none)
#   hostname         → which host this was, for the login hint
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  payload = "/var/lib/cala-reinstall";
in {
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
    ./installer.nix
  ];

  # The netboot default (zstd -19) takes minutes to build for little RAM saved.
  netboot.squashfsCompression = "zstd -Xcompression-level 6";

  # netboot-minimal drops linux-firmware (mkOverride 70); the ISO has it, and a
  # bare-metal NIC that needs a blob would come back with no network.
  hardware.enableRedistributableFirmware = lib.mkOverride 60 true;

  cala.installer.mediaDir = payload;

  # A live image has no state to version; the ISO profile does the same.
  system.stateVersion = lib.mkDefault lib.trivial.release;

  # The appended cpio lands in stage 1's rootfs, which is freed at switch-root:
  # copy it into the real (tmpfs) root first.
  boot.initrd.systemd.services.cala-reinstall-payload = {
    description = "Carry the cala-reinstall payload into the installer";
    wantedBy = ["initrd.target"];
    after = ["initrd-fs.target"];
    before = ["initrd-nixos-activation.service" "initrd.target"];
    unitConfig = {
      DefaultDependencies = false;
      ConditionPathExists = "/cala-reinstall";
    };
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /sysroot${payload}
      chmod 0700 /sysroot${payload}
      cp -a /cala-reinstall/. /sysroot${payload}/
      if [ -d /cala-reinstall/ssh ]; then
        mkdir -p /sysroot/etc/ssh
        cp -a /cala-reinstall/ssh/. /sysroot/etc/ssh/
        # cp -a gave it the payload dir's 0700, and the .pub files 0600.
        chmod 0755 /sysroot/etc/ssh
        chmod 0644 /sysroot/etc/ssh/*.pub
        rm -rf /sysroot${payload}/ssh
      fi
      if [ -f /cala-reinstall/hostname ]; then
        install -m 0644 /cala-reinstall/hostname /sysroot/etc/cala-reinstall-from
      fi
    '';
  };

  services.openssh.authorizedKeysFiles = ["${payload}/authorized_keys"];

  environment.loginShellInit = lib.mkBefore ''
    if [ -r /etc/cala-reinstall-from ]; then
      echo "cala-reinstall: this was '$(cat /etc/cala-reinstall-from)'. Reinstall it with install-cala-m-os (wiki: ISO-Installer;"
      echo "  hosts without calamoose.install.wipeAllDisks need disko first, then INSTALL_SKIP_DISKO=1)."
    fi
  '';

  # DHCP needs nothing; a host with static addressing (no DHCP on that network)
  # would otherwise be unreachable after the jump.
  systemd.services.cala-reinstall-network = {
    description = "Restore the reinstalled host's static network config";
    wantedBy = ["multi-user.target"];
    wants = ["NetworkManager.service"];
    after = ["NetworkManager.service"];
    before = ["network-online.target" "cala-nix-token.service"];
    unitConfig.ConditionPathExists = "${payload}/network";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [config.networking.networkmanager.package pkgs.coreutils pkgs.gawk];
    script = ''
      # Lines: addr4|addr6 <mac> <cidr> · dyn4|dyn6 <mac> (it also had DHCP/RA)
      #        gw4|gw6 <mac> <ip> · dns <ip>
      # One profile per NIC, bound by MAC rather than name: interface names can
      # differ here, and a physical NIC's driver may only load after this runs.
      net=${payload}/network
      pick() { awk -F'\t' -v k="$1" -v m="$2" '$1 == k && tolower($2) == m {print $3}' "$net"; }
      has() { awk -F'\t' -v k="$1" -v m="$2" '$1 == k && tolower($2) == m {f = 1} END {exit !f}' "$net"; }
      dns4=$(awk -F'\t' '$1 == "dns" && $2 !~ /:/ {print $2}' "$net" | paste -sd, -)
      dns6=$(awk -F'\t' '$1 == "dns" && $2 ~ /:/ {print $2}' "$net" | paste -sd, -)
      for mac in $(awk -F'\t' '$1 ~ /^addr[46]$/ {print tolower($2)}' "$net" | sort -u); do
        name="cala-reinstall-''${mac//:/}"
        args=(connection add type ethernet con-name "$name" ethernet.mac-address "$mac" connection.autoconnect-priority 100)
        for v in 4 6; do
          addrs=$(pick "addr$v" "$mac" | paste -sd, -)
          gw=$(pick "gw$v" "$mac" | head -n1)
          dns=dns$v
          if [ -z "$addrs" ]; then
            args+=("ipv$v.method" auto)
          elif has "dyn$v" "$mac"; then
            # DHCP/RA as before, plus the static addresses; the lease brings the gateway.
            args+=("ipv$v.method" auto "ipv$v.addresses" "$addrs")
          else
            args+=("ipv$v.method" manual "ipv$v.addresses" "$addrs")
            if [ -n "$gw" ]; then
              args+=("ipv$v.gateway" "$gw")
              # A gateway outside the carried prefix (Hetzner Cloud: a /32 behind
              # 172.31.1.1) needs a direct host route first. NetworkManager adds
              # one by itself today but warns (1.58+) that this will change, so
              # spell it out; harmless when the gateway is on-link anyway.
              [ "$v" = 6 ] || args+=("ipv$v.routes" "$gw/32")
            fi
            if [ -n "''${!dns}" ]; then args+=("ipv$v.dns" "''${!dns}"); fi
          fi
        done
        echo "restoring $mac: $(pick addr4 "$mac" | paste -sd' ' -) $(pick addr6 "$mac" | paste -sd' ' -)"
        nmcli "''${args[@]}"
        nmcli connection up "$name" >/dev/null 2>&1 || echo "$name comes up when its NIC appears" >&2
      done
    '';
  };

  # What cala-reinstall loads. The command line has no console= on purpose:
  # cala-reinstall adds the running host's own, so output goes where it did.
  system.build.calaKexec = pkgs.linkFarm "cala-installer-kexec" [
    {
      name = "bzImage";
      path = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
    }
    {
      name = "initrd";
      path = "${config.system.build.netbootRamdisk}/initrd";
    }
    {
      name = "cmdline";
      path = pkgs.writeText "cmdline" "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}";
    }
  ];
}
