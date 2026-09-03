##################################
#                                #
#   Gaming Desktop + Stream Src  #
#                                #
##################################
{
  inputs,
  cala-m-os,
  lib,
  initialInstallMode,
  ...
}: let
  import_users = ["gamer"];

  machine_type = "Workstation";
  machine_uuid = "B850-MAX";
in {
  calamoose.enableSecrets = false;
  calamoose.version = "2.2.0";
  calamoose.style = "thecompany"; # The Company, Inc. brand theme

  imports =
    [
      # Common Core Config
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
        extra_user_modules = {
          gamer = [
            "cobblemon-overlay"
            "davinci-resolve"
            "tci-run"
          ];
        };
      })
    ]
    # bookkeeper (books) + its PRIVATE flake input need a GitHub PAT to fetch; keep the
    # whole block out of the minimal installer pass (no token / proton-secrets there).
    ++ lib.optional (!initialInstallMode) {
      imports = [inputs.bookkeeper.nixosModules.default];

      services.calamoose-books.enable = true;

      # Fetch-time GitHub token for the private bookkeeper-app input, via Proton Pass
      # (reusing the "nix-github-token" vault item). battlestation keeps
      # enableSecrets = false, so drive services.proton-secrets DIRECTLY for JUST this
      # one secret rather than the calamoose.secrets facade — that avoids pulling the
      # shared online secrets (admin_password, …) and changing this box's login source.
      # Seed the Proton session first on the running host: `sudo proton-secrets login`
      # (or place a Proton PAT at patFile).
      services.proton-secrets = {
        enable = true;
        patFile = "/var/lib/proton-pass-cli/pat";
        secrets."nix-github-token" = {
          vaultName = "Cala-M-OS";
          itemTitle = "nix-github-token";
          field = "secret";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      # Hand the token to Nix. A missing !include is non-fatal, so the box still
      # evaluates before the secret is populated (public inputs unaffected).
      nix.extraOptions = ''
        !include /run/proton-secrets/nix-github-token
      '';

      # Self-heal: with systemd stage-1 the initrd activation has no network, so the
      # Proton fetch there fails and /run/proton-secrets/* starts empty every boot.
      # The calamoose.secrets facade ships a self-heal for exactly this, but only under
      # a real backend — and we're keeping enableSecrets = false — so replicate a small
      # one. It re-runs activation once network-online is up (re-executing the Proton
      # fetch WITH network) and never fails the boot; same-generation `switch test`
      # computes zero unit changes, so the live session is untouched.
      systemd.services.nix-github-token-selfheal = {
        description = "Fetch the GitHub build token once the network is up (initrd activation has none)";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "300";
        };
        script = ''
          set -u
          tok=/run/proton-secrets/nix-github-token
          [ -e "$tok" ] && { echo "[nix-github-token] already present"; exit 0; }
          n=0
          while [ "$n" -lt 5 ]; do
            n=$((n + 1))
            echo "[nix-github-token] attempt $n: re-running activation with network up..."
            /run/current-system/bin/switch-to-configuration test || true
            [ -e "$tok" ] && { echo "[nix-github-token] populated."; exit 0; }
            sleep 5
          done
          echo "[nix-github-token] WARNING: token still missing after $n attempts (check the proton-secrets session)." >&2
          exit 0
        '';
      };
    };

  # Drop the built Cobblemon Initiative .mrpack in ~/TCI (or repoint mrpackPath at
  # a synced dist/ dir / file); the template rebuilds whenever the pack hash changes.
  # Firewall scoped to the studio subnet (where `broadcast`/Companion lives), so no
  # other device can spawn instances. battlestation (10.1.10.30) and broadcast
  # (10.1.10.15) share the studio subnet, so the button reaches :8778 intra-subnet.
  #
  # To lock the overlay's attempt/cemetery to the run counter, add:
  #   syncOverlay = true;
  #   overlayTokenFile = <the shared cobblemon-overlay token>;  # see the module README
  services.tci-run = {
    enable = true;
    allowedSources = ["${cala-m-os.ip.studio.subnet}"];
  };

  networking.hostName = "battlestation";

  # Audio (PipeWire will handle the GPU's audio output)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
}
