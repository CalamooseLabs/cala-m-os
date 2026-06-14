# Persistent per-host machine overrides.
#
# Maps a host name to a machine_uuid that host should build to, OVERRIDING the
# host's own default machine. Normally this is empty.
#
# The installer writes an entry here when invoked as:
#     install-cala-m-os <host> <machine>
# so that this physical box keeps building <host> onto <machine> on every future
# `nixos-rebuild`. During the install itself the override is also passed live via
# the MACHINE_OVERRIDE environment variable (which takes precedence over this
# file), so disko and the first install pass pick it up before this file exists.
#
# The machine_type (Workstation vs VM) is detected automatically from whichever
# of machines/{workstations,vms} contains the named machine — see
# machines/resolve.nix.
#
# Example:
#   {
#     devbox = "MS-01";   # build the devbox host onto the MS-01 machine
#   }
{
}
