{
  host = {
    path = ./host;
    description = "a simple host flake";
    welcomeText = ''
      # Cala M OS Host Template
    '';
  };

  module = {
    path = ./module;
    description = "a simple module flake";
    welcomeText = ''
      # Cala M OS Module Template
    '';
  };

  secret = {
    path = ./secret;
    description = "a simple agenix to be added to a module";
    welcomeText = ''
      # Cala M OS Secret Template
      Use `agenix -e [secretfile] -i ./identities/yubi.key` to get started
    '';
  };

  user = {
    path = ./user;
    description = "a simple user nix flake";
    welcomeText = ''
      # Cala M OS User Template
    '';
  };
}
