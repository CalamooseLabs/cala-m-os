{
  inputs,
  pkgs,
  modulesPath,
  lib,
  ...
}: {
  imports = [(modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  # Enable SSH in the boot process.
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce ["multi-user.target"];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ./public_keys/id_ed25519_sk.pub
    ./public_keys/backup_id_ed25519_sk.pub
  ];

  networking.hostName = lib.mkForce "cala-m-os-installer";

  programs.bash.completion.enable = true;

  environment.systemPackages = with pkgs; [
    disko
    git
    neovim
    # Hardware inspection + network tooling the cala-installer TUI surfaces (and
    # that are handy in a dropped shell): PCI/USB, NVMe, DMI, full hw summary,
    # interface state, DNS lookups, and gum itself.
    gum
    pciutils
    usbutils
    nvme-cli
    dmidecode
    lshw
    iproute2
    dnsutils
    # cala-installer (the auto-running gum TUI) drives install-cala-m-os (the
    # 5-step backend); both ship from the antlers scripts collection, with their
    # bash-completion. disko stays on PATH above so Step One resolves it offline.
    # proton-secrets provides the `proton-secrets login` used to set up online
    # (Proton Pass) hosts during install. Defaults (flake ref, clone URL, version
    # attr, /mnt + /etc/nixos paths, hub/root passwords) match this ISO.
    inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.install-cala-m-os
    inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.cala-installer
    inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.proton-secrets
  ];

  services.pcscd.enable = true;

  # The base installation-device profile already enables NetworkManager (+ nmtui),
  # which the installer uses to bring up wired/Wi-Fi before it fetches the flake
  # and (for online hosts) logs into Proton Pass. Reassert it explicitly so the
  # dependency is visible and survives a base-profile change.
  networking.networkmanager.enable = true;

  # Auto-launch the installer TUI on the physical console (tty1) only, so SSH and
  # other VTs still get a plain root shell. The env guard prevents a relaunch loop
  # when the user drops to a shell from within the TUI.
  environment.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ] && [ -z "''${CALA_INSTALLER_STARTED:-}" ]; then
      export CALA_INSTALLER_STARTED=1
      cala-installer || true
    fi
  '';

  isoImage = {
    squashfsCompression = "lz4";
    forceTextMode = true;
  };
}
