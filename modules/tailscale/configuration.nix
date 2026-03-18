{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./secrets
  ];

  nixpkgs.overlays = [
    (import ./overlay.nix)
  ];

  services.tailscale = {
    enable = true;
  };

  # ...
  networking.firewall = {
    # always allow traffic from your Tailscale network
    trustedInterfaces = ["tailscale0"];

    # allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [config.services.tailscale.port];
  };

  # create a oneshot job to authenticate to Tailscale
  # EXPIRES ON 03/29/2026
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = ["network-pre.target" "tailscale.service"];
    wants = ["network-pre.target" "tailscale.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig.Type = "oneshot";

    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # read the pre-auth key from the decrypted secret
      authkey=$(cat /run/agenix/tailscale-preauth-key)

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up -authkey "$authkey"
    '';
  };
}
