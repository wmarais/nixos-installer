{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [ 
    zfstools
    python312 
    vscode-with-extensions
  ];
}

