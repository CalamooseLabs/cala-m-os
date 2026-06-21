{inputs, ...}: {
  # `remote-kvm [homelab|broadcast]` (antlers): open a KVM-over-IP web UI in a
  # chromium --app window, preferring the DNS URL on-network and the IP off it.
  imports = [inputs.antlers.homeManagerModules.antlers-scripts];
  programs.antlers-scripts = {
    enable = true;
    remote-kvm = {
      enable = true;
      defaultTarget = "broadcast";
      targets = {
        homelab = {
          dns = "http://kvm.calamos.family/";
          ip = "http://10.10.10.26/";
        };
        broadcast = {
          dns = "http://broadcast.thecompany.inc";
          ip = "http://10.1.10.5";
        };
      };
    };
  };
}
