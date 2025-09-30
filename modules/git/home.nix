{cala-m-os, ...}: {
  programs.git = {
    enable = true;
    userName = cala-m-os.globalFullName;
    userEmail = cala-m-os.globalDefaultEmail;
    signing = {
      key = "50D56BF0B93CA212"; # Backup Key: 8AA1F614601153B5
      signByDefault = true;
    };
    extraConfig = {
      safe.directory = [
        "/etc/nixos"
      ];
    };
  };
}
