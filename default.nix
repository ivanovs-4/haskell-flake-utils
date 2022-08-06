{ flake-utils }:
let
  # This function tries to capture a common haskell cabal package flake pattern.
  simpleCabal2flake = import ./simpleCabal2flake.nix { inherit lib flake-utils; };
  simpleCabalProject2flake = import ./simpleCabalProject2flake.nix { inherit lib flake-utils; };

  haskellPackagesOverrideComposable = pkgs: hpOverrides:
    pkgs.haskellPackages.override (oldAttrs: {
      overrides =
        pkgs.lib.composeExtensions
          (oldAttrs.overrides or (_: _: { }))
          hpOverrides;
    });

  tunePackages = pkgs: old: with pkgs.lib;
      attrsets.mapAttrs (n: fs: trivial.pipe old.${n} fs);

  jailbreakUnbreak = pkgs: pkg:
      pkgs.haskell.lib.doJailbreak (pkg.overrideAttrs (_: { meta = { }; }));

  loadOverlay = obj:
    if obj == null
      then [ ]
      else [ (maybeImport obj) ];

  maybeImport = obj:
    if (builtins.typeOf obj == "path") || (builtins.typeOf obj == "string")
      then
        import obj
      else
        obj;

  maybeCall = obj: args:
    if (builtins.typeOf obj == "lambda")
      then
        obj args
      else
        obj;

  foldCompose = builtins.foldl'
    (f: g: a: f (g a))
    (x: x);

  lib = {
    inherit
      simpleCabal2flake
      simpleCabalProject2flake
      haskellPackagesOverrideComposable
      tunePackages
      jailbreakUnbreak
      loadOverlay
      maybeImport
      maybeCall
      foldCompose
      ;
  };
in
lib
