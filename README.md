# haskell-flake-utils

**STATUS: experimental**

Pure Nix flake utility functions for haskell cabal packages.

## Usage

### `simpleCabal2flake -> attrs -> attrs`

This function should be useful for most common use-cases where you have
a simple flake that builds a haskell cabal package. It takes nixpkgs and
a bunch of other parameters and outputs a value that is compatible as a flake
output with overlay that overrides haskellPackages and adds current package to
it.

Input:
```nix
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
, # pass the list of supported systems
  systems ? [ "x86_64-linux" ]
}: null
```

#### Example

Here is how it looks like in practice:

[$ examples/simple-cabal2flake/flake.nix](examples/simple-cabal2flake/flake.nix) as nix
```nix
{
  description = "Haskell flake utils demo";

  inputs.flake-utils.url = "github:ivanovs-4/haskell-flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    haskell-flake-utils.lib.simpleFlake {
      inherit self nixpkgs;
      name = "simple-cabal-package-flake";
      shell = {pkgs}: pkgs.mkShell {
        buildInputs = with pkgs.haskellPackages; [
          ghcid
          cabal-install
          (ghcWithPackages (h: with h; [
          ]))
        ];
      };
    };
}
```
