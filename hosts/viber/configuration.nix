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
  # profile's programs.github-repo-puller.repos — persist them so the clones survive.
  # The option only exists outside initialInstallMode (minimal installer skips the
  # user modules), so guard against it being absent.
  repoDirs =
    lib.optionals (config.programs ? github-repo-puller)
    (map (d: lib.removePrefix homePrefix d)
      (lib.unique (lib.attrValues config.programs.github-repo-puller.repos)));
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

  # Auto-login on the console TTY — drop straight into a shell, no password prompt.
  services.getty.autologinUser = owner;

  # Impermanent root: keep the SSH host keys on /persistent so sshd reads and
  # (re)generates them in one stable place. Listing them under
  # preservation.files instead bind-mounts initially-empty files into /etc/ssh,
  # which races sshd's own key generation — the keys end up regenerated every
  # boot (clients hit "host key changed") or sshd fails to load an empty key and
  # never starts, so inbound SSH breaks. Pointing hostKeys straight at the
  # persistent path sidesteps the bind mount entirely.
  services.openssh.hostKeys = lib.mkIf (!initialInstallMode) [
    {
      path = "/persistent/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/persistent/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  # Make the key-generation oneshot wait for /persistent to be mounted before it
  # runs `ssh-keygen` against the paths above. Default systemd ordering already
  # puts it after local-fs.target, but RequiresMountsFor states the dependency
  # explicitly so the keys can never land on the tmpfs root by accident.
  systemd.services.sshd-keygen.unitConfig.RequiresMountsFor =
    lib.mkIf (!initialInstallMode) "/persistent/etc/ssh";

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
      # SSH host keys are NOT listed here — sshd owns them directly at
      # /persistent/etc/ssh/* via services.openssh.hostKeys above.
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
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
