{
  cores,
  memory,
}: {
  lib,
  inputs,
  ...
}: {
  imports = [inputs.microvm.nixosModules.microvm];

  microvm = {
    # VM resources
    vcpu = cores;
    mem = 1024 * memory;
    balloon = lib.mkDefault true;

    # Hypervisor settings
    hypervisor = lib.mkDefault "qemu";
    graphics.enable = lib.mkDefault false;

    writableStoreOverlay = lib.mkDefault "/nix/.rw-store";
  };

  networking = {
    useDHCP = false;
  };

  # microvm.nix disables wait-online (systemd-networkd issue 29388). The guests
  # have exactly one static macvtap link, so waiting for ANY routable interface
  # is safe and bounded — and it makes network-online.target mean something for
  # the NFS mounts and the first-boot restores ordered behind it (mount.nfs
  # does not retry a failed name lookup).
  systemd.network.wait-online = {
    enable = lib.mkForce true;
    anyInterface = true;
    timeout = 30;
  };

  # Guests see the host's /nix/store through an overlay. A garbage collection
  # run inside a guest (the server profile's weekly `nh clean`, or nix.gc) would
  # whiteout every host path outside the guest's own closure — paths a later
  # host rebuild may hand the guest again. The host's closure already protects
  # everything a guest needs; never collect from inside.
  programs.nh.clean.enable = lib.mkForce false;
  nix.gc.automatic = lib.mkForce false;
}
