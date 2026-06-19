##################################
#                                #
#   viber — headless dev box     #
#   ZIMA workstation (TTY-only)   #
#                                #
##################################
{
  inputs,
  lib,
  config,
  cala-m-os,
  initialInstallMode,
  ...
}: let
  import_users = ["developer"];
  machine_type = "Workstation";
  machine_uuid = "ZIMA";

  owner = cala-m-os.globals.defaultUser;
  homePrefix = "/home/${owner}/";

  # Repo target folders (relative to the user's home) come from the developer
  # profile's services.github-repo-puller.repos — persist them so the clones survive.
  # The option only exists outside initialInstallMode (minimal installer skips the
  # user modules), so guard against it being absent.
  repoDirs =
    lib.optionals (config.services ? github-repo-puller)
    (map (d: lib.removePrefix homePrefix d)
      (lib.unique (lib.attrValues config.services.github-repo-puller.repos)));
in {
  calamoose.enableSecrets = true;
  calamoose.version = "0.0.1-alpha";

  imports = [
    inputs.preservation.nixosModules.default

    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {};
    })
  ];

  networking.hostName = "viber";

  # TTY-only: no greeter / compositor.
  services.greetd.enable = lib.mkForce false;

  # ZIMA root is tmpfs (impermanent) — keep system state + dev essentials + repos.
  # Skip in the minimal installer (no `hub` user exists to anchor home paths).
  preservation = lib.mkIf (!initialInstallMode) {
    enable = true;
    preserveAt."/persistent" = {
      directories = [
        "/etc/nixos"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
      ];
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
      users.${owner}.directories =
        [
          {
            directory = ".ssh";
            mode = "0700";
          }
          {
            directory = ".gnupg";
            mode = "0700";
          }
          ".config"
          ".local/share"
          ".claude"
        ]
        ++ repoDirs;
    };
  };
}
