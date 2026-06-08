{lib, ...}: {
  options.calamoose.enableSecrets = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to load agenix secrets on this host.";
  };
}
