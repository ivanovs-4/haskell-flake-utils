{
description = "Haskell cabal package";

inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    haskell-flake-utils.url = "github:ivanovs-4/haskell-flake-utils";
    haskell-flake-utils.inputs.flake-utils.follows = "flake-utils";

    # another-simple-haskell-flake.url = "something";

    # some-cabal-pkg.url = "github:example/some-cabal-pkg";
    # some-cabal-pkg.flake = false;
};

outputs = { self, nixpkgs, flake-utils, haskell-flake-utils, ... }@inputs:
  flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
    haskell-flake-utils.lib.simpleCabal2flake {
      inherit self nixpkgs system;

      # DON'T FORGET TO PUT YOUR PACKAGE NAME HERE, REMOVING `throw`
      name = throw "put your package name here!";

      ## Optional parameters follow

      # nixpkgs config
      # config = { };

      # Add another haskell flakes as requirements
      # haskellFlakes = [ inputs.another-simple-haskell-flake ];

      # Use this to load other flakes overlays to supplement nixpkgs
      # preOverlays = [ ];

      # Pass either a function or a file
      # preOverlay = ./overlay.nix;

      # Override haskell packages
      # hpPreOverrides = { pkgs }: new: old:
      #   with pkgs.haskell.lib; with haskell-flake-utils.lib;
      #   tunePackages pkgs old {
      #     some-haskellPackages-package = [ dontHaddock ];
      #   } // {
      #     some-cabal-pkg = ((jailbreakUnbreak pkgs) (dontCheck (old.callCabal2nix "some-cabal-pkg" inputs.some-cabal-pkg {})));
      #   };

      # Arguments for callCabal2nix
      # cabal2nixArgs = {
      # };

      # Maps to the devShell output. Pass in a shell.nix file or function
      # shell = ./shell.nix

      # Additional build intputs of the default shell
      # shellExtBuildInputs = [];

      # Wether to build hoogle in the default shell
      # shellWithHoogle = true;

    }
  );
}
