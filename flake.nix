{
  description = "Pure Nix flake utility functions for haskell cabal packages";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils }: {

    lib = import ./. { inherit flake-utils; };

    templates = {

      simple-cabal-flake = {
        path = ./examples/simple-cabal2flake;
        description = "A Hakell cabal package";
      };

      simple-hs2flake = {
        path = ./examples/simple-hs2flake;
        description = "A Hakell ghc packages";
      };

      # simple-cabal-project-flake = {
      #   path = ./examples/simple-cabal-project2flake;  # TODO implement it
      #   description = "A Hakell cabal project";
      # };

    };

  };

}
