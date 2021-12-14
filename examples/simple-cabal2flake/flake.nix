{
  description = "Haskell cabal package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    haskell-flake-utils.url = "github:ivanovs-4/haskell-flake-utils";

    # another-simple-haskell-flake.url = "something";

  };

  outputs = { self, nixpkgs, ... }@inputs:
    inputs.haskell-flake-utils.lib.simpleCabal2flake {
      inherit self nixpkgs;

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
      # hpPreOverrides = { pkgs, system }: new: old: {
      # };

      # Arguments for callCabal2nix
      # cabal2nixArgs = {
      # };

      # Maps to the devShell output. Pass in a shell.nix file or function
      # shell = ./shell.nix

      # Additional build intputs of the default shell
      # shellExtBuildInputs = [];

      # Wether to build hoogle in the default shell
      # shellwithHoogle = true;

      # Pass the list of supported systems
      # systems = [ "x86_64-linux" ];

    };
}
