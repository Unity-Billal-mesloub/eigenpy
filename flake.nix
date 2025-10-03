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
            default = self'.packages.eigenpy-eigen5;
            eigen3 = pkgs.eigen.overrideAttrs (super: rec {
              version = "3.4.1";
              src = pkgs.fetchFromGitLab {
                inherit (super.src) owner repo;
                tag = version;
                hash = "sha256-NSq1tUfy2thz5gtsyASsKeYE4vMf71aSG4uXfrX86rk=";
              };
              patches = [ ];
              postPatch = "";
            });
            eigen5 = self'.packages.eigen3.overrideAttrs (super: rec {
              version = "5.0.0";
              src = pkgs.fetchFromGitLab {
                inherit (super.src) owner repo;
                tag = version;
                hash = "sha256-L1KUFZsaibC/FD6abTXrT3pvaFhbYnw+GaWsxM2gaxM=";
              };
            });
            eigenpy-eigen3 =
              (pkgs.python3Packages.eigenpy.override { eigen = self'.packages.eigen3; }).overrideAttrs
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
            eigenpy-eigen5 = self'.packages.eigenpy-eigen3.override { eigen = self'.packages.eigen5; };
          };
        };
    };
}
