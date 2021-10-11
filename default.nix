{ flake-utils }:
let
  # This function tries to capture a common haskell cabal package flake pattern.
  simpleCabal2flake = import ./simpleCabal2flake.nix { inherit lib flake-utils; };

  haskellPackagesOverrideComopsable = pkgs: hpOverrides:
    pkgs.haskellPackages.override (oldAttrs: {
      overrides =
        pkgs.lib.composeExtensions
          (oldAttrs.overrides or (_: _: { }))
          hpOverrides;
    });

  lib = {
    inherit
      simpleCabal2flake
      haskellPackagesOverrideComopsable
      ;
  };
in
lib
