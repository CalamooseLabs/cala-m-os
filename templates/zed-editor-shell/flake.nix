{
  description = "Development environment with custom zed-editor configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zed-wrapper = {
      url = "github:CalamooseLabs/cala-m-os/programs/zed-editor/wrapper.nix";
      flake = false;
    };
  };

  outputs = { nixpkgs, ... } @ inputs :
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { system = system; };
  in
  {
    devShells.${system}.default = import ./shell.nix {
      inherit pkgs;
      inherit inputs;
    };
  };
}
