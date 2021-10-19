{ lib, flake-utils }:
# This function returns a flake outputs-compatible schema.
{
  # pass an instance of self
  self
, # pass an instance of the nixpkgs flake
  nixpkgs
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
  hpPreOverrides ? (_: _: { })
, # arguments for callCabal2nix
  cabal2nixArgs ? { }
, # maps to the devShell output. Pass in a shell.nix file or function.
  shell ? null
, # additional build intputs of the default shell
  shellExtBuildInputs ? []
, # wether to build hoogle in the default shell
  shellwithHoogle ? true
, # pass the list of supported systems
  systems ? [ "x86_64-linux" ]
}:
let

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

  outputs = flake-utils.lib.eachSystem systems (system:
    let
      overlayWithHpPreOverrides = final: prev: {
        haskellPackages = lib.haskellPackagesOverrideComopsable prev hpPreOverrides;
      };

      cabal2nixArgs_ = maybeCall cabal2nixArgs { pkgs = pkgsWithOur; inherit system; };

      hpOverrides =
        (new: old: { ${name} = old.callCabal2nix name self cabal2nixArgs_; });

      overlayOur = final: prev: {
        haskellPackages = lib.haskellPackagesOverrideComopsable prev hpOverrides;
      };

      pkgsWithOur = import nixpkgs {
        inherit system config;
        overlays = self.overlays.${system};
      };

    in (
      {

        overlay = nixpkgs.legacyPackages.${system}.lib.composeManyExtensions ([ ]
          ++ preOverlays
          ++ (map (fl: fl.overlay.${system}) haskellFlakes)
          ++ (loadOverlay preOverlay)
          ++ [ overlayWithHpPreOverrides ]
          ++ [ overlayOur ]
          );

        overlays = ([ self.overlay.${system} ]);

        packages.${name} = pkgsWithOur.haskellPackages.${name};

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
              withHoogle = shellwithHoogle;
              buildInputs = (
                with pkgs.haskellPackages; ([
                  ghcid
                  cabal-install
                ])
                ++
                (maybeCall shellExtBuildInputs { pkgs = pkgsWithOur; inherit system; })
              );
            }
        ) { pkgs = pkgsWithOur; inherit system; };
      }

    )
  );

in outputs
