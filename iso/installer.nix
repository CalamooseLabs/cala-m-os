{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: let
  # What the installer offers, computed from the flake itself so the lists can
  # never drift from it: every host output except the installer images, and
  # every machine directory (machines are not flake outputs, so the tree is
  # read). cala-installer and the install-cala-m-os completion take them from
  # the environment (CALA_INSTALLER_*); once online cala-installer also refreshes
  # them from the flake ref it installs from, so a host added after this image
  # was built still shows up.
  hostNames =
    builtins.filter (n: n != "iso" && !lib.hasPrefix "installer-" n)
    (builtins.attrNames inputs.self.nixosConfigurations);
  machineDirs = dir:
    builtins.attrNames (lib.filterAttrs (n: t: t == "directory" && !lib.hasPrefix "_" n)
      (builtins.readDir dir));

  # The installer's own tools (./tools.nix): antlers' cala-installer TUI and the
  # token-aware install-cala-m-os shim, built against THIS image's package set
  # so the same files serve the aarch64 kexec image (webhost). The same set is
  # the flake's packages.<system>.installer-tools, which the TUI's "Update the
  # installer" pulls and re-launches from.
  tools = import ./tools.nix {
    inherit pkgs inputs lib;
    mediaDir = config.cala.installer.mediaDir;
  };
  # proton-secrets provides the `proton-secrets login` used to set up online
  # (Proton Pass) hosts during install; built the same way (antlers' own
  # packages.<system> is x86_64-only, and its overlay is not used here).
  proton-secrets = pkgs.callPackage (inputs.antlers + "/flakes/proton-secrets/package.nix") {};
in {
  # Everything the live installer needs, whatever it boots from: imported by
  # ./default.nix (the ISO) and ./kexec.nix (RAM-only, kexec'd by cala-reinstall).
  imports = [
    # Proton PAT on the media → GitHub token for private flake inputs.
    ./calapat.nix
  ];

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
    # 5-step backend, here antlers' script with its bash-completion; the
    # token-aware shim that shadows it comes from ./calapat.nix). disko stays on
    # PATH above so Step One resolves it offline. Defaults (flake ref, clone
    # URL, version attr, /mnt + /etc/nixos paths, hub/root passwords) match
    # this image.
    tools.backend
    tools.cala-installer
    proton-secrets
  ];

  # The host and machine pickers (see the let above).
  environment.variables = {
    CALA_INSTALLER_HOSTS = lib.concatStringsSep " " hostNames;
    CALA_INSTALLER_MACHINES = lib.concatStringsSep " " (machineDirs ../machines/workstations);
    CALA_INSTALLER_VM_MACHINES = lib.concatStringsSep " " (machineDirs ../machines/vms);
  };

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
}
