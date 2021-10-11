{
  description = "Pure Nix flake utility functions for haskell cabal packages";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils }: {
    lib = import ./. { inherit flake-utils; };
  };
}
