{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [  ];

  shellHook = ''
    echo "Welcome to dev shell"
  '';
}
