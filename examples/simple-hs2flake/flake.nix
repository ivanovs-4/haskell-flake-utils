{
  description = "Collection of a one-file haskell programs in one flake";
  inputs.haskell-flake-utils.url = "github:ivanovs-4/haskell-flake-utils";

  outputs = { self, nixpkgs, haskell-flake-utils }:
    haskell-flake-utils.lib.simpleHs2flake {
      inherit self nixpkgs;
      pname = "ants";

      # src = ./.;   # Uncomment if this flake.nix is not in the root of the repo

      hpackages = h: with h; [
        optparse-applicative
        typed-process
      ];

      tune-hpackages = (pkgs:
        with pkgs.haskell.lib;
        with haskell-flake-utils.lib; {
          lens-datetime = [ (jailbreakUnbreak pkgs) dontCheck ];
        });

      runtimeDepsDefault = {pkgs}: with pkgs; [
      ];

      runtimeDeps = {pkgs}: with pkgs; {
        "run-guile" = [
          guile
        ];
      };

      extShellBuildInputs = {pkgs}: with pkgs; [
        haskellPackages.haskell-language-server
      ];

    };
}
