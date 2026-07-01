# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
{...}: {
  calamoose.secrets = {
    "work_credentials" = {
      agenixFile = ./work_credentials.age;
      reference = "pass://REPLACE_ME/work_credentials";
    };
    "proton_vpn.conf" = {
      agenixFile = ./proton_vpn.conf.age;
      reference = "pass://REPLACE_ME/proton_vpn.conf";
    };
  };
}
