# Backend-neutral secret declarations for the UniFi Protect camera-wall service
# (see modules/secrets/configuration.nix). These live with the module that consumes
# them, but are decrypted on the PARENT host (agenix) and shared into the `security`
# microVM guest at /run/hostsecrets/* by the vm-manager virtiofs share. So this file is
# imported by the guest's HOST (hosts/homelab/vms.nix), NOT by the module's own
# configuration.nix — the guest reads the host-decrypted files and must not re-decrypt.
{...}: {
  calamoose.secrets = {
    "protect-api-key" = {
      agenixFile = ./protect-api-key.age;
      reference = "pass://REPLACE_ME/protect-api-key";
    };
    "protect-admin-password" = {
      agenixFile = ./protect-admin-password.age;
      reference = "pass://REPLACE_ME/protect-admin-password";
    };
  };
}
