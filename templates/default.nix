{
  cala-m-os-program = {
    path = ./cala-m-os-program;
    description = "a simple program flake";
    welcomeText = ''
      # Cala M OS Program Template
    '';
  };

  cala-m-os-user = {
    path = ./cala-m-os-user;
    description = "a simple user nix flake";
    welcomeText = ''
      # Cala M OS User Template
    '';
  };

  dev-shell = {
    path = ./dev-shell;
    description = "a simple direnv nix flake shell";
    welcomeText = ''
      # Nix Dev Shell Template
    '';
  };

  zed-editor-shell = {
    path = ./zed-editor-shell;
    description = "a simple direnv zed editor flake shell";
    welcomeText = ''
      # Zed Dev Shell Template
    '';
  };

  nkc-lease-amendment = {
    path = ./nkc-lease-amendment;
    description = "Lease Amendment template in LaTeX";
    welcomeText = ''
      Ensure to run direnv allow
    '';
  };
}
