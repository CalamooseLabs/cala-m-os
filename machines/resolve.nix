# Resolve which hardware a host actually builds to.
#
# Given a host's default machine_type/machine_uuid and an optional override
# (from the MACHINE_OVERRIDE env var or machine-override.nix, threaded in as
# `machineOverride` via specialArgs), return the effective machine identity and
# its on-disk path. When an override is supplied, the machine_type is detected
# automatically from whichever of machines/{workstations,vms} contains it, so a
# caller only ever needs to supply the machine name.
{
  machine_type,
  machine_uuid,
  machineOverride ? "",
}: let
  hasOverride = machineOverride != "";

  uuid =
    if hasOverride
    then machineOverride
    else machine_uuid;

  # Auto-detect the type of an overridden machine from where it lives.
  overrideIsWorkstation = builtins.pathExists (./workstations + "/${uuid}");

  type =
    if !hasOverride
    then machine_type
    else if overrideIsWorkstation
    then "Workstation"
    else "VM";

  isVM = type == "VM" || type == "vm";

  root =
    if isVM
    then ./vms
    else ./workstations;

  path = toString (root + "/${uuid}");
in {
  inherit uuid type isVM path;
}
