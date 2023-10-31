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
, # systems to pass to flake-utils.lib.eachSystem
  systems ? flake-utils.lib.defaultSystems
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
, # arguments for callCabal2nix. It could be a function which accepts a set with pkgs.
  cabal2nixArgs ? { }
, # maps to the devShell output. Pass in a shell.nix file or function.
  shell ? null
, # additional build intputs of the default shell. It could be a function which accepts a set with pkgs.
  shellExtBuildInputs ? []
, # wether to build hoogle in the default shell
  shellwithHoogle ? true
, # we can choose compiler from pkgs.haskell.packages
  compiler ? null
, # overlays that will be used to build the package but will not be added to self.overlay
  localOverlays ? []
}: null
```

#### Example

[flake.nix](examples/simple-cabal2flake/flake.nix)

Here is how it looks like in practice:

```nix
{
description = "Haskell cabal package";

inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    haskell-flake-utils.url = "github:ivanovs-4/haskell-flake-utils";
};

outputs = { self, nixpkgs, haskell-flake-utils, ... }@inputs:
    haskell-flake-utils.lib.simpleCabal2flake {
      inherit self nixpkgs;
      systems = [ "x86_64-linux" ];

      name = "cabal-package-name";

    };
}
```

Nix flake template available:
```
nix flake init -t github:ivanovs-4/haskell-flake-utils#simple-cabal-flake
```


This makes the following commands available
```
nix develop
cabal build
```

```
nix develop -c cabal repl
```

```
nix develop -c ghcid
```

```
nix build
./result/bin/<binary-name>
```

Also this new flake may be used in `haskellFlakes` from other such flakes.



### `simpleHs2flake`

#### Example

[flake.nix](examples/simple-hs2flake/flake.nix)

Nix flake template available:
```
nix flake init -t github:ivanovs-4/haskell-flake-utils#simple-hs2flake
```
