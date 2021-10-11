{
  description = "Haskell flake utils demo";

  inputs.flake-utils.url = "github:ivanovs-4/haskell-flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.simpleFlake {
      inherit self nixpkgs;

      name = "simple-cabal2flake";

      # overlay = ./overlay.nix;

      cabal2nixArgs = {};

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
