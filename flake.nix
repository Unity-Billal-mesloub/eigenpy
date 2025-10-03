{
  description = "Bindings between Numpy and Eigen using Boost.Python";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem =
        { pkgs, self', ... }:
        {
          apps.default = {
            type = "app";
            program = pkgs.python3.withPackages (_: [ self'.packages.default ]);
          };
          devShells.default = pkgs.mkShell { inputsFrom = [ self'.packages.default ]; };
          packages = {
            default = self'.packages.eigenpy;
            # Test eigen v5
            eigen = pkgs.eigen.overrideAttrs (super: {
              src = pkgs.fetchFromGitLab {
                inherit (super.src) owner repo;
                tag = "5.0.0";
                hash = "sha256-L1KUFZsaibC/FD6abTXrT3pvaFhbYnw+GaWsxM2gaxM=";
              };
              patches = [ ];
              postPatch = "";
            });
            eigenpy =
              (pkgs.python3Packages.eigenpy.override { inherit (self'.packages) eigen; }).overrideAttrs
                (_: {
                  src = pkgs.lib.fileset.toSource {
                    root = ./.;
                    fileset = pkgs.lib.fileset.unions [
                      ./CMakeLists.txt
                      ./doc
                      ./include
                      ./package.xml
                      ./python
                      ./src
                      ./unittest
                    ];
                  };
                });
          };
        };
    };
}
