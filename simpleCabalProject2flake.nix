{ lib, flake-utils }: with lib;
# This function returns a flake outputs-compatible schema.
{
  # pass an instance of self
  self
, # pass an instance of the nixpkgs flake
  nixpkgs
, # systems to pass to flake-utils.lib.eachSystem
  systems ? flake-utils.lib.defaultSystems
, # package name
  name
, #
  packageNames ? []
, #
  packageDirs ? {}
, # nixpkgs config
  config ? { }
, # add another haskell flakes as requirements
  haskellFlakes ? [ ]
, # use this to load other flakes overlays to supplement nixpkgs
  preOverlays ? [ ]
, # pass either a function or a file
  preOverlay ? null
, # override haskell packages
  hpPreOverrides ? ({...}: _: _: { })
, # how to add our own packages to haskell packages
  hpOverrides ? null
, # arguments for callCabal2nix
  cabal2nixArgs ? { }
, #
  packageCabal2nixArgs ? {}
, # maps to the devShell output. Pass in a shell.nix file or function.
  shell ? null
, # additional build intputs of the default shell
  shellExtBuildInputs ? []
, # wether to build hoogle in the default shell
  shellWithHoogle ? false
  # we can choose compiler from pkgs.haskell.packages
, compiler ? null
  # overlays that will be used to build the package but will not be added to self.overlay
, localOverlays ? []
  # list of override functions from haskell.lib
, packagePostOverrides ? {pkgs}: []
}:

let
    localOverlays_ = localOverlays ++ (
      if compiler == null
        then []
        else [ (final: prev: { haskellPackages = prev.haskell.packages.${compiler}; }) ]
      );

    overlayWithHpPreOverrides = final: prev: {
      haskellPackages = lib.haskellPackagesOverrideComposable prev (hpPreOverrides { pkgs = prev; });
    };

    overlayOur = final: prev:
      let
        pkgs = prev;
      in {
        haskellPackages = lib.haskellPackagesOverrideComposable pkgs (
          if hpOverrides != null
          then hpOverrides { inherit pkgs; }
          else (new: old:
            with pkgs.lib.attrsets;
            genAttrs (packageNames_ pkgs) (n:
              old.callCabal2nixWithOptions n self ("--subpath ${ attrByPath [n] n packageDirs }") (
                attrByPath [n]
                  (maybeCall cabal2nixArgs { inherit pkgs; })
                  (maybeCall packageCabal2nixArgs { inherit pkgs; })
              )
            )
          )
        );
      };

    packageNames_ = pkgs: pkgs.lib.lists.unique ([ name ] ++ packageNames);

    defaultOverlay = final: prev:
      prev.lib.composeManyExtensions ([ ]
        ++ preOverlays
        ++ (map (fl: fl.overlays.default) haskellFlakes)
        ++ (loadOverlay preOverlay)
        ++ [ overlayWithHpPreOverrides ]
        ++ [ overlayOur ]
        ) final prev;

in
  {
    overlays = {"default" = defaultOverlay; };
  }
  //
  (flake-utils.lib.eachSystem systems (system:
    let

      pkgs = import nixpkgs {
        inherit system config;
        overlays = localOverlays_ ++ [self.overlays.default];
      };

      packages_ = flake-utils.lib.flattenTree
        (builtins.mapAttrs
          (_name: (foldCompose (maybeCall packagePostOverrides { inherit pkgs; })))
          (getAttrs (packageNames_ pkgs) pkgs.haskellPackages)
        );

      getAttrs = names: attrs: pkgs.lib.attrsets.genAttrs names (n: attrs.${n});

    in {
      packages = packages_ // {
        "default" = pkgs.symlinkJoin {
          name = "all";
          paths = builtins.attrValues packages_;
        };
      };

      devShells = {"default" = (
        if shell != null
        then maybeImport shell
        else
          {pkgs, ...}:
          pkgs.haskellPackages.shellFor {
            packages = _: pkgs.lib.attrsets.attrVals (packageNames_ pkgs) pkgs.haskellPackages;
            withHoogle = shellWithHoogle;
            buildInputs = (
              with pkgs.haskellPackages; ([
                ghcid
                cabal-install
              ])
              ++
              (maybeCall shellExtBuildInputs { inherit pkgs; })
            );
          }
        ) { inherit pkgs; };
      };

    }
  ))
