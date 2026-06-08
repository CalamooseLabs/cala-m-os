{
  users_list,
  machine_type,
  machine_uuid,
  extra_user_modules ? {},
  ...
}: {
  inputs,
  lib,
  cala-m-os,
  pkgs,
  ...
}: let
  usersPath = ../../users;
  modulesPath = toString ../../modules;

  # Multi-user: 2+ users in the list → hub switcher profile is auto-inserted as
  # the primary user and the listed users become real named system users.
  # Single-user: the one user is mapped to the hub username as before.
  isMultiUser = builtins.length users_list > 1;

  effectiveUsersList =
    if isMultiUser
    then ["hub"] ++ users_list
    else users_list;

  defaultUser = lib.elemAt effectiveUsersList 0;

  isDefaultUser = name: name == defaultUser;
  getUserDef = name:
    import (toString (usersPath + "/${name}/default.nix")) {
      inherit inputs lib;
      isDefaultUser = isDefaultUser name;
    };

  userDefs = map getUserDef effectiveUsersList;
  user_imports = map (d: d.module) userDefs;
  allModuleNames = lib.unique (lib.concatLists (map (d: d.modules) userDefs));
  system_config_imports = map (name: import (modulesPath + "/${name}/configuration.nix")) allModuleNames;

  # Extra per-host modules keyed by user profile name
  getExtraModuleNames = profileName: extra_user_modules.${profileName} or [];
  allExtraModuleNames = lib.unique (lib.concatLists (map getExtraModuleNames effectiveUsersList));
  # Only import configuration.nix for modules not already covered by user defs
  newExtraModuleNames = lib.subtractLists allModuleNames allExtraModuleNames;
  extra_system_config_imports = map (name: import (modulesPath + "/${name}/configuration.nix")) newExtraModuleNames;

  # Username for a profile — mirrors users/_core/default.nix logic
  getUserName = profileName:
    if isDefaultUser profileName
    then cala-m-os.globals.defaultUser
    else profileName;

  # Extra home-manager imports per profile, only when home.nix exists
  makeExtraHomeImports = profileName:
    lib.concatMap (name: let
      path = modulesPath + "/${name}/home.nix";
    in lib.optional (builtins.pathExists path) (import path))
    (getExtraModuleNames profileName);

  isVM = machine_type == "VM" || machine_type == "vm";
  machine_root =
    ../../machines
    + (
      if isVM
      then "/vms"
      else "/workstations"
    );
  machine_path = toString (machine_root + "/${machine_uuid}");

  machine_configuration = import (toString (machine_path + "/configuration.nix"));
in {
  options.calamoose.enableSecrets = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to load agenix secrets on this host.";
  };

  imports =
    [
      inputs.disko.nixosModules.disko
      inputs.stylix.nixosModules.stylix
      (import ./home.nix {
        machine_path = machine_path;
      })
      machine_configuration
      ../../modules/user-switching/configuration.nix
    ]
    ++ user_imports
    ++ system_config_imports
    ++ extra_system_config_imports
    ++ lib.optional (machine_type != "VM") ./non-vm.nix;

  # Inject extra home-manager modules per user
  home-manager.users = lib.mkMerge (map (profileName: let
    username = getUserName profileName;
    extraHomeImports = makeExtraHomeImports profileName;
  in
    lib.optionalAttrs (extraHomeImports != []) {
      "${username}".imports = extraHomeImports;
    })
  effectiveUsersList);

  # Boot loader
  boot = {
    loader = {
      timeout = lib.mkForce 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    plymouth = {
      enable = lib.mkDefault true;
    };

    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    # Trying to move this to disko
    tmp.useTmpfs = true;

    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  # Remove manuals, as we google everything anyways
  documentation.enable = lib.mkDefault false;

  # Enable Firewall
  networking.firewall.enable = true;

  # Set Colorado timezone
  time.timeZone = "${cala-m-os.globals.TZ}";

  # Garbage Collection & Flakes
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };

    settings = {
      auto-optimise-store = lib.mkDefault false;
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel" cala-m-os.globals.defaultUser];
    };
  };

  # Login Service
  services.greetd = {
    enable = lib.mkDefault true;
    settings = {
      default_session = {
        user = lib.mkForce "${cala-m-os.globals.defaultUser}";
        command = lib.mkDefault "${pkgs.bash}/bin/bash";
      };
    };
  };

  # Finer grain privileged process control
  security.polkit.enable = true;

  # Original State Version
  system.stateVersion = "24.11"; # Do not change
}
// lib.optionalAttrs isMultiUser {
  userSwitching.enable = true;
  userSwitching.switchableUsers = users_list;
}
