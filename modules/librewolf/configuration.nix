{...}: {
  # librewolf's pinned build is flagged insecure; permit both the wrapper and the
  # unwrapped package (the wrapper pulls the latter in) so hosts using this module
  # (e.g. `basic` → simple) still evaluate. Bump these strings when librewolf does.
  nixpkgs.config.permittedInsecurePackages = [
    "librewolf-151.0.2-1"
    "librewolf-unwrapped-151.0.2-1"
  ];
}
