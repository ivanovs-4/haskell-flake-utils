{ lib, flake-utils }: with lib;
# This function returns a flake outputs-compatible schema.
{
  # pass an instance of self
  self
, # pass an instance of the nixpkgs flake
  nixpkgs
, # system
  system
, # package name
  name
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
}:
let
      pkgs = import nixpkgs {
        inherit system config;
        overlays = localOverlays_ ++ self.overlays.${system};
      };

      localOverlays_ = localOverlays ++ (
        if compiler == null
          then []
          else [ (final: prev: { haskellPackages = prev.haskell.packages.${compiler}; }) ]
        );

      overlayWithHpPreOverrides = final: prev: {
        haskellPackages = lib.haskellPackagesOverrideComposable prev (hpPreOverrides { inherit pkgs; });
      };

      hpOverrides_ = (
          if hpOverrides != null
          then hpOverrides { inherit pkgs; }
          else new: old: {
              "${name}" = old.callCabal2nix name self (maybeCall cabal2nixArgs { inherit pkgs; });
            }
        );

      overlayOur = final: prev: {
        haskellPackages = lib.haskellPackagesOverrideComposable prev hpOverrides_;
      };

      getAttrs = names: attrs: pkgs.lib.attrsets.genAttrs names (n: attrs.${n});

in
      {

        overlay = final: prev: prev.lib.composeManyExtensions ([ ]
          ++ preOverlays
          ++ (map (fl: fl.overlay.${system}) haskellFlakes)
          ++ (loadOverlay preOverlay)
          ++ [ overlayWithHpPreOverrides ]
          ++ [ overlayOur ]
          ) final prev;

        overlays = ([ self.overlay.${system} ]);

        packages = flake-utils.lib.flattenTree {
          "${name}" = pkgs.haskellPackages.${name};
        };

        defaultPackage = self.packages.${system}.${name};

      }

      //

      {
        devShell = (
          if shell != null
          then maybeImport shell
          else
            {pkgs, ...}:
            pkgs.haskellPackages.shellFor {
              packages = _: [ pkgs.haskellPackages.${name} ];
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
      }
