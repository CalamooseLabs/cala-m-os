# Hetzner Cloud guest — networking + console policy for a KVM VM on Hetzner's
# CLOUD line (CX/CPX/CCX x86, CAX arm64). Imported by the HETZNER-* machines;
# a host supplies its own addresses through calamoose.hetznerCloud.*.
#
# Hetzner's Cloud network is ROUTED (Layer 3), not a flat Ethernet segment:
#
#   IPv4  The server owns a single /32. The gateway is 172.31.1.1, which is NOT
#         inside that /32, so the default route has to be installed on-link.
#         Hetzner's DHCP hands all of this out, and systemd-networkd copes with
#         an off-subnet router (it adds a host route to it first), so DHCP is
#         the default here. Hetzner itself warns that "the Cloud Server network
#         model is always based on Layer 3, so automatic network configuration
#         may fail with some custom operating systems" — so a host can pin the
#         address instead (ipv4Address); DHCP is then off entirely and the
#         route is written out explicitly.
#   IPv6  The server owns a /64, but Hetzner sends NO router advertisements:
#         SLAAC never happens and IPv6AcceptRA would only wait for nothing. The
#         address must be static (ipv6Address, conventionally <prefix>::1/64)
#         with the link-local gateway fe80::1.
#   DNS   Hetzner's resolvers. The DHCP lease carries the IPv4 pair; the static
#         path sets both pairs (nameservers). systemd-resolved is on, because
#         networkd only hands lease DNS to resolved — without it a DHCP-only box
#         boots with an empty /etc/resolv.conf.
#
# The addresses are only known once the server exists, so a FIRST install runs
# on DHCP (both options null). Fill them in afterwards and redeploy; that is
# also the moment to publish AAAA records — Let's Encrypt validates over IPv6
# first, so an AAAA record without working IPv6 breaks certificate issuance.
#
# Console: the only out-of-band access is Hetzner's web (noVNC) console, so the
# boot menu stays visible for a moment (roll back a bad generation) and there
# is no Plymouth splash hiding the text console. The QEMU guest agent is on,
# because the Console's "reset root password" works through it — the break-glass
# login for a box whose accounts are otherwise key-only.
#
# Firmware: CPX/CCX/CAX servers boot UEFI (systemd-boot + ESP, as laid out in
# the HETZNER-* disko.nix files). The cheap CX line is still created in legacy
# BIOS mode and would need a GRUB/BIOS-boot layout instead — don't put a Cala-M-OS
# host on a CX type without changing its disko.nix.
{
  config,
  lib,
  modulesPath,
  ...
}: let
  cfg = config.calamoose.hetznerCloud;
  staticV4 = cfg.ipv4Address != null;
  staticV6 = cfg.ipv6Address != null;
  # Accept a bare address or a CIDR; Hetzner's prefixes are fixed (/32, /64).
  withPrefix = prefix: addr:
    if lib.hasInfix "/" addr
    then addr
    else "${addr}/${prefix}";
in {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  options.calamoose.hetznerCloud = {
    interface = lib.mkOption {
      type = lib.types.str;
      default = "en*";
      description = ''
        systemd.network `Name=` match for the public NIC. The virtio NIC is
        enp1s0 on current Hetzner images; a glob keeps the exact name out of it.
      '';
    };

    ipv4Address = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "203.0.113.10";
      description = ''
        The server's primary IPv4 (the Cloud Console shows it). null (default)
        leaves IPv4 to Hetzner's DHCP. Setting it turns DHCP OFF: the address is
        configured as a /32 with the on-link default route via ipv4Gateway —
        the static configuration Hetzner documents for OSes whose DHCP client
        can't handle the off-subnet gateway.
      '';
    };

    ipv4Gateway = lib.mkOption {
      type = lib.types.str;
      default = "172.31.1.1";
      description = "Hetzner Cloud's IPv4 gateway (outside the server's /32; routed on-link).";
    };

    ipv6Address = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "2a01:4f8:c012:3456::1/64";
      description = ''
        An address inside the server's /64 (the Cloud Console shows the prefix;
        ::1 is the convention), with the prefix length. null (default) means no
        public IPv6 at all — Hetzner sends no router advertisements, so there is
        no automatic path. Confirm `curl -6` works before publishing AAAA records.
      '';
    };

    ipv6Gateway = lib.mkOption {
      type = lib.types.str;
      default = "fe80::1";
      description = "Hetzner Cloud's IPv6 gateway (link-local).";
    };

    nameservers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default =
        ["185.12.64.1" "185.12.64.2"]
        ++ lib.optionals staticV6 ["2a01:4ff:ff00::add:1" "2a01:4ff:ff00::add:2"];
      defaultText = lib.literalExpression ''["185.12.64.1" "185.12.64.2"] ++ (the IPv6 pair when ipv6Address is set)'';
      description = ''
        Resolvers written into the network unit on the static path(s). Hetzner's
        recursive resolvers by default; under plain DHCP the lease supplies them.
      '';
    };
  };

  config = {
    # One virtio NIC, no Wi-Fi, no VPNs: NetworkManager has nothing to manage
    # and would fight networkd for the link. _core/non-vm.nix defaults it on.
    networking.networkmanager.enable = lib.mkForce false;
    networking.useDHCP = false;

    systemd.network = {
      enable = true;
      networks."10-wan" = {
        matchConfig.Name = cfg.interface;
        networkConfig = {
          DHCP =
            if staticV4
            then "no"
            else "ipv4";
          # Never offered on Hetzner Cloud; see the header.
          IPv6AcceptRA = false;
        };
        address =
          lib.optional staticV4 (withPrefix "32" cfg.ipv4Address)
          ++ lib.optional staticV6 (withPrefix "64" cfg.ipv6Address);
        routes =
          lib.optional staticV4 {
            Gateway = cfg.ipv4Gateway;
            # 172.31.1.1 is outside the /32: without this the kernel refuses
            # the default route ("Nexthop has invalid gateway").
            GatewayOnLink = true;
          }
          ++ lib.optional staticV6 {Gateway = cfg.ipv6Gateway;};
        dns = lib.optionals (staticV4 || staticV6) cfg.nameservers;
        linkConfig.RequiredForOnline = "routable";
      };
    };

    # Lease/static DNS reaches /etc/resolv.conf only through resolved (header).
    services.resolved.enable = lib.mkDefault true;

    # Hetzner's Console "reset root password" talks to the guest agent (header).
    services.qemuGuest.enable = lib.mkDefault true;

    # Console policy (header). mkOverride 900 sits between _core's mkDefault
    # (1000) and a host's plain assignment (100), so a host can still change it.
    boot.loader.timeout = lib.mkOverride 900 3;
    boot.plymouth.enable = lib.mkForce false;
  };
}
