{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "remote-kvm" ''
      set -eu

      # Which KVM to open. Defaults to broadcast.
      target="''${1:-broadcast}"

      case "$target" in
        homelab)
          dns_url="http://kvm.calamos.family/"
          ip_url="http://10.10.10.26/"
          ;;
        broadcast)
          dns_url="http://broadcast.thecompany.inc"
          ip_url="http://10.1.10.5"
          ;;
        *)
          echo "usage: remote-kvm [homelab|broadcast]" >&2
          exit 1
          ;;
      esac

      # Probe the DNS hostname: if it responds we're on that KVM's network and
      # use the DNS URL; if it doesn't, we're off-network so fall back to the IP.
      if ${pkgs.curl}/bin/curl --silent --output /dev/null --connect-timeout 3 "$dns_url"; then
        kvm_url="$dns_url"
      else
        kvm_url="$ip_url"
      fi

      # Dedicated, throwaway-ish profile (per target) so the main profile stays untouched.
      profile="$HOME/.local/share/remote-kvm/$target"
      mkdir -p "$profile"

      # Launch chromium in --app mode: a single window with no tabs, omnibox,
      # bookmarks or other browser chrome — just the KVM page. This is the
      # native, stripped-down replacement for the old librewolf
      # userChrome.css + user.js minimal-UI hack.
      #
      #   --user-data-dir                  per-target throwaway profile (isolated instance)
      #   --autoplay-policy=...            KVM video stream must start without a click
      #   --force-dark-mode                dark browser UI (menus, scrollbars)
      #   --enable-features=...ForceDark   dark web content; drop this one if the
      #                                    KVM UI already themes itself and ends
      #                                    up looking double-inverted
      #   --disable-features=HttpsUpgrades the KVM is http-only, so don't let
      #                                    chromium auto-upgrade the connection
      exec ${pkgs.chromium}/bin/chromium \
        --user-data-dir="$profile" \
        --app="$kvm_url" \
        --no-first-run \
        --no-default-browser-check \
        --disable-session-crashed-bubble \
        --autoplay-policy=no-user-gesture-required \
        --force-dark-mode \
        --enable-features=WebContentsForceDark \
        --disable-features=HttpsUpgrades
    '')
  ];
}
