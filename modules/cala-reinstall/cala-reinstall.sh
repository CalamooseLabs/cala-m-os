# shellcheck shell=bash
# Body of `cala-reinstall` (see ./configuration.nix). CALA_REINSTALL_FLAKE is
# set by the wrapper.

usage() {
  cat <<'EOF'
usage: cala-reinstall [--dry-run] [--yes] [--flake REF | --image DIR]
                      [--token-file FILE | --pat-file FILE | --no-token] [--no-keys] [--no-network]

Replace this running host with the Cala-M-OS installer, in RAM (kexec). The
disks are untouched until you run install-cala-m-os there; a hard reset before
then boots this system again.

  --dry-run          build the payload and load the image, then unload it
  --yes              skip the type-the-hostname confirmation
  --flake REF        flake providing installer-kexec (default below)
  --image DIR        a ready kexec image (bzImage, initrd, cmdline) instead
  --token-file FILE  GitHub `access-tokens = …` line for private flake inputs
                     (default: whatever this host's nix already has)
  --pat-file FILE    Proton Pass PAT (default: /var/lib/proton-pass-cli/pat, if any)
  --no-token         go ahead without a GitHub token or PAT (no private inputs)
  --no-keys          don't carry SSH authorized keys or host keys
  --no-network       don't carry static addresses (DHCP networks need none)
EOF
  echo "Default flake: $CALA_REINSTALL_FLAKE (programs.cala-reinstall.flake)"
}
die() {
  echo "cala-reinstall: $*" >&2
  exit 1
}

IMAGE=""
YES=0
DRY=0
TOKEN_FILE=""
PAT_FILE=""
NO_TOKEN=0
KEYS=1
NET=1
while [ $# -gt 0 ]; do
  case "$1" in
    --flake) CALA_REINSTALL_FLAKE="${2:?--flake needs a flake ref}"; shift 2 ;;
    --image) IMAGE="${2:?--image needs a directory}"; shift 2 ;;
    --token-file) TOKEN_FILE="${2:?--token-file needs a path}"; shift 2 ;;
    --pat-file) PAT_FILE="${2:?--pat-file needs a path}"; shift 2 ;;
    --no-token) NO_TOKEN=1; shift ;;
    --no-keys) KEYS=0; shift ;;
    --no-network) NET=0; shift ;;
    --dry-run) DRY=1; shift ;;
    --yes) YES=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 64 ;;
  esac
done

[ "$(id -u)" -eq 0 ] || die "run as root: sudo cala-reinstall"
HOST=$(cat /proc/sys/kernel/hostname)

if [ -z "$IMAGE" ]; then
  echo "Building the installer kexec image from $CALA_REINSTALL_FLAKE..."
  IMAGE=$(nix --extra-experimental-features 'nix-command flakes' build --refresh \
    --no-link --print-out-paths "$CALA_REINSTALL_FLAKE#installer-kexec") ||
    die "could not build $CALA_REINSTALL_FLAKE#installer-kexec."
fi
for f in bzImage initrd cmdline; do
  [ -r "$IMAGE/$f" ] || die "$IMAGE has no $f; not an installer-kexec image."
done

# The installer briefly holds the initrd twice while unpacking it, then keeps the
# store (about the initrd's size) plus ~1 GiB to run. Loading needs a RAM copy to
# append the payload to, plus the kernel's own copy.
isz=$(stat -L -c %s "$IMAGE/initrd")
gib=$((1024 * 1024 * 1024))
memtotal=$(awk '/^MemTotal:/ {print $2 * 1024}' /proc/meminfo)
memavail=$(awk '/^MemAvailable:/ {print $2 * 1024}' /proc/meminfo)
if [ "$memtotal" -lt $((2 * isz + gib)) ]; then
  die "the installer needs about $(((2 * isz + gib) / gib + 1)) GiB of RAM; this box has $((memtotal / gib)) GiB. Use the ISO instead."
fi
if [ "$memavail" -lt $((2 * isz + gib / 4)) ]; then
  die "not enough free memory to load the image (need ~$(((2 * isz) / gib + 1)) GiB available). Stop some services and retry."
fi

umask 077
WORK=$(mktemp -d /run/cala-reinstall.XXXXXX)
BIG=""
LOADED=0
JUMPING=0
# A loaded image outliving this script would turn the next plain `reboot` into
# a jump to the installer (systemctl kexecs whenever an image is loaded).
cleanup() {
  if [ "$LOADED" -eq 1 ] && [ "$JUMPING" -eq 0 ]; then kexec --unload || true; fi
  if [ -n "$BIG" ]; then umount "$BIG" 2>/dev/null || true; fi
  rm -rf "$WORK"
}
trap cleanup EXIT
trap 'exit 130' INT TERM HUP
P="$WORK/root/cala-reinstall"
mkdir -p "$P"
printf '%s\n' "$HOST" >"$P/hostname"
carried=()

# GitHub token: an explicit file, else whatever this host's nix already uses
# (e.g. modules/nix-github-token), so the installer needs no Proton round trip.
if [ -n "$TOKEN_FILE" ]; then
  [ -r "$TOKEN_FILE" ] || die "cannot read $TOKEN_FILE."
  cp "$TOKEN_FILE" "$P/nix-access-tokens.conf"
  carried+=("GitHub token from $TOKEN_FILE")
else
  tok=$(nix --extra-experimental-features nix-command config show access-tokens 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
  if [ -n "$tok" ]; then
    printf 'access-tokens = %s\n' "$tok" >"$P/nix-access-tokens.conf"
    carried+=("this host's GitHub token for Nix")
  fi
  unset tok
fi

# Proton PAT: lets the installer fetch the token itself, and is what
# cala-installer seeds onto an online-secrets host it reinstalls.
if [ -n "$PAT_FILE" ]; then
  [ -r "$PAT_FILE" ] || die "cannot read $PAT_FILE."
  cp "$PAT_FILE" "$P/pat"
  carried+=("Proton Pass PAT from $PAT_FILE")
elif [ -r /var/lib/proton-pass-cli/pat ]; then
  cp /var/lib/proton-pass-cli/pat "$P/pat"
  carried+=("this host's Proton Pass PAT")
fi

if [ "$KEYS" -eq 1 ]; then
  # Plain key lines only: options such as command="…" are not carried.
  { cat /etc/ssh/authorized_keys.d/* /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys 2>/dev/null || true; } |
    grep -E '^(ssh-|sk-|ecdsa-)' | sort -u >"$P/authorized_keys" || true
  if [ -s "$P/authorized_keys" ]; then
    carried+=("$(wc -l <"$P/authorized_keys") SSH authorized key(s), for root")
  else
    rm -f "$P/authorized_keys"
  fi
  # services.openssh.hostKeys (from the wrapper): impermanent hosts keep them
  # outside /etc/ssh. Stored under the standard names the installer's sshd reads.
  mkdir "$P/ssh"
  read -ra hostkeys <<<"${CALA_REINSTALL_HOSTKEYS:-}"
  for k in "${hostkeys[@]}"; do
    if [ -r "$k" ] && [ -r "$k.pub" ]; then
      cp -L "$k" "$P/ssh/$(basename "$k")"
      cp -L "$k.pub" "$P/ssh/$(basename "$k").pub"
    fi
  done
  if [ -n "$(find "$P/ssh" -mindepth 1 -print -quit)" ]; then
    carried+=("SSH host keys (same fingerprint)")
  else
    rmdir "$P/ssh"
  fi
fi

if [ "$NET" -eq 1 ]; then
  # The NIC (by MAC) that carries $1's addresses: itself if physical, else a
  # bridge's physical member. Nothing for VLANs, bonds and other virtual links.
  nic_mac() {
    local d="/sys/class/net/$1" m
    if [ -e "$d/device" ]; then
      cat "$d/address"
      return 0
    fi
    if [ -d "$d/brif" ]; then
      for m in "$d"/brif/*; do
        if [ -e "/sys/class/net/$(basename "$m")/device" ]; then
          cat "/sys/class/net/$(basename "$m")/address"
          return 0
        fi
      done
    fi
    return 1
  }
  # Static = never expires; DHCP/RA addresses have lifetimes and need no help,
  # but a NIC that had both keeps DHCP on (dyn4/dyn6) next to the static ones.
  while IFS=$'\t' read -r dev fam cidr; do
    if mac=$(nic_mac "$dev"); then
      case "$fam" in inet) v=4 ;; *) v=6 ;; esac
      printf 'addr%s\t%s\t%s\n' "$v" "$mac" "$cidr"
    else
      echo "cala-reinstall: not carrying $cidr on $dev (no physical NIC behind it)." >&2
    fi
  done < <(ip -j addr show | jq -r '.[] | .ifname as $if | .addr_info[]
    | select(.scope == "global" and .valid_life_time == 4294967295)
    | [$if, .family, "\(.local)/\(.prefixlen)"] | @tsv') >"$P/network"
  if [ -s "$P/network" ]; then
    while IFS=$'\t' read -r dev fam; do
      if mac=$(nic_mac "$dev"); then
        case "$fam" in inet) v=4 ;; *) v=6 ;; esac
        printf 'dyn%s\t%s\n' "$v" "$mac" >>"$P/network"
      fi
    done < <(ip -j addr show | jq -r '.[] | .ifname as $if | .addr_info[]
      | select(.scope == "global" and .valid_life_time != 4294967295) | [$if, .family] | @tsv' | sort -u)
    for fam in 4 6; do
      while IFS=$'\t' read -r dev gw; do
        if mac=$(nic_mac "$dev"); then printf 'gw%s\t%s\t%s\n' "$fam" "$mac" "$gw" >>"$P/network"; fi
      done < <(ip "-$fam" -j route show default | jq -r '.[] | select(.gateway) | [.dev, .gateway] | @tsv')
    done
    resolv=/etc/resolv.conf
    if [ -r /run/systemd/resolve/resolv.conf ]; then resolv=/run/systemd/resolve/resolv.conf; fi
    awk '$1 == "nameserver" && $2 !~ /^(127\.|::1$)/ {print "dns\t" $2}' "$resolv" >>"$P/network"
    if ! grep -q '^dns' "$P/network"; then
      echo "cala-reinstall: warning: no upstream DNS server found (only a local resolver?);" >&2
      echo "  the installer will have no DNS on a static-only network." >&2
    fi
    carried+=("static network: $(grep -c '^addr' "$P/network") address(es)")
  else
    rm -f "$P/network"
  fi
fi

if [ ! -e "$P/nix-access-tokens.conf" ] && [ ! -e "$P/pat" ] && [ "$NO_TOKEN" -eq 0 ]; then
  die "carrying no GitHub token or Proton PAT, so a host with private flake inputs
  (e.g. tci-cloud) can't be evaluated in the installer. Pass --token-file FILE
  (an 'access-tokens = github.com=...' line) or --pat-file FILE, or --no-token if
  this host has no private inputs."
fi

# Append the payload to the image's initrd: the kernel unpacks concatenated
# archives in order, so /cala-reinstall/ appears in stage 1's root. Staged on a
# private tmpfs, never disk: it holds the secrets, and has to fit in RAM to boot.
(cd "$WORK/root" && find cala-reinstall -print0 | cpio --null -o -H newc -R 0:0 --quiet) >"$WORK/payload.cpio"
need=$(($(stat -L -c %s "$IMAGE/initrd") + 64 * 1024 * 1024))
BIG="$WORK/big"
mkdir "$BIG"
mount -t tmpfs -o "size=$need,mode=0700" tmpfs "$BIG" || {
  BIG=""
  die "could not stage the image in RAM."
}
INITRD="$BIG/initrd"
cat "$IMAGE/initrd" >"$INITRD"
truncate -s %4 "$INITRD"
cat "$WORK/payload.cpio" >>"$INITRD"

CMDLINE=$(cat "$IMAGE/cmdline")
read -ra kargs </proc/cmdline
for t in "${kargs[@]}"; do
  case "$t" in console=*) CMDLINE="$CMDLINE $t" ;; esac
done

echo
echo "This replaces the running '$HOST' with the Cala-M-OS installer, in RAM."
echo "  image:    $IMAGE"
if [ "${#carried[@]}" -gt 0 ]; then
  printf '  carrying: %s\n' "${carried[@]}"
fi
echo "Disks are untouched until you run install-cala-m-os there. A hard reset"
echo "before then boots '$HOST' again."
if [ "$DRY" -eq 0 ] && [ "$YES" -ne 1 ]; then
  read -rp "Type the hostname ($HOST) to continue: " ans || ans=""
  [ "$ans" = "$HOST" ] || die "aborted."
fi

kexec --load "$IMAGE/bzImage" --initrd="$INITRD" --command-line="$CMDLINE" ||
  die "kexec could not load the image (kernel lockdown / Secure Boot?)."
LOADED=1
rm -f "$INITRD"

if [ "$DRY" -eq 1 ]; then
  echo "Dry run: payload built and image loaded; unloading. Not jumping."
  exit 0
fi

echo "Jumping to the installer; this session will drop. Reconnect over SSH or the console."
sync
# From here the shutdown kills this session (SIGHUP), which must not unload.
JUMPING=1
trap '' HUP
if ! systemctl kexec; then
  JUMPING=0
  die "systemctl kexec failed; image unloaded, '$HOST' keeps running."
fi
