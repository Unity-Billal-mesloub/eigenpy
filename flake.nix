{
  description = "Bindings between Numpy and Eigen using Boost.Python";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { self, lib, ... }:
      {
        systems = inputs.nixpkgs.lib.systems.flakeExposed;
        flake.overlays = {
          default = final: prev: {
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (python-final: python-prev: {
                eigenpy = python-prev.eigenpy.overrideAttrs {
                  src = lib.fileset.toSource {
                    root = ./.;
                    fileset = lib.fileset.unions [
                      ./CMakeLists.txt
                      ./doc
                      ./include
                      ./package.xml
                      ./python
                      ./src
                      ./unittest
                    ];
                  };
                };
              })
            ];
          };
          eigen_5 = final: _prev: {
            eigen = final.eigen_5;
          };
        };
        perSystem =
          {
            pkgs,
            pkgs-eigen_5,
            self',
            system,
            ...
          }:
          {
            _module.args = {
              pkgs = import inputs.nixpkgs {
                inherit system;
                overlays = [ self.overlays.default ];
              };
              pkgs-eigen_5 = import inputs.nixpkgs {
                inherit system;
                overlays = [
                  self.overlays.eigen_5
                  self.overlays.default
                ];
              };
            };
            apps.default = {
              type = "app";
              program = pkgs.python3.withPackages (_: [ self'.packages.default ]);
            };
            packages = {
              default = self'.packages.eigenpy;
              eigenpy = pkgs.python3Packages.eigenpy;
              eigenpy-eigen_5 = pkgs-eigen_5.python3Packages.eigenpy;
            };
          };
      }
    );
}
