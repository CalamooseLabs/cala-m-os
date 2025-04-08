{
  cala-m-os-program = {
    path = ./cala-m-os-program;
    description = "a simple program flake";
    welcomeText = ''
      # Cala M OS Program Template
    '';
  };

  cala-m-os-secret = {
    path = ./cala-m-os-secret;
    description = "a simple agenix to be added to a module";
    welcomeText = ''
      # Cala M OS Secret Template
      Use `agenix -e [secretfile] -i ./identities/yubi.key` to get started
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

  spreadsheet-pdf = {
    path = ./spreadsheet-pdf;
    description = "Spreadsheet to PDF template in SC-IM";
    welcomeText = ''
      Ensure to run direnv allow
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
