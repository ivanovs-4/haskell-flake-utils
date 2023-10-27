# # This function returns a flake outputs-compatible schema.
{ lib, flake-utils }:
{ self
, src ? null
, nixpkgs
, systems ? flake-utils.lib.defaultSystems
, pname
, version ? "0.0.1"
, scripts ? [ ]
, hpackages ? _: [ ]
}:

let
  scripts' = if scripts != [] then scripts else [pname];
  script = builtins.head scripts';

  withDefaultAllJoined = pkgs: kv: kv // {
    "default" = pkgs.symlinkJoin {
      name = pname;
      paths = builtins.attrValues kv;
    };
  };

  forEachToAttrs = xs: f: with builtins; listToAttrs (map (x: {name = x; value = f x;}) xs);

  buildPackage = pkgs: sname: pkgs.stdenv.mkDerivation {
    inherit version;
    pname = sname;

    src = if src != null then src else self;

    buildInputs = [ (pkgs.haskellPackages.ghcWithPackages hpackages) ];

    buildPhase = ''
      ghc -O3 -static -threaded \
        -with-rtsopts="-N4 -A256m -H256m -K64m -AL256m -I0" \
        ${sname}.hs
    '';

    installPhase = ''
      mkdir -p $out/bin
      mv ${sname} $out/bin/
    '';

    meta = with pkgs.lib; {
      description = "One-off script `${sname}` from package `${pname}`";
      license = licenses.gpl2Only;
      platforms = with platforms; unix;
    };
  };

in
with lib;
let
  outputs = flake-utils.lib.eachSystem systems (system:
    let pkgs = nixpkgs.legacyPackages.${system};

    in {
      packages = if builtins.length scripts' == 1
        then { "default" = buildPackage pkgs (builtins.head scripts'); }
        else withDefaultAllJoined pkgs (forEachToAttrs scripts' (buildPackage pkgs))
        ;

      apps = (forEachToAttrs scripts' (sname: {
        type = "app";
        program = "${self.packages.${system}.${sname}}/bin/${sname}";
      }));

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs.haskellPackages; [
          (ghcWithPackages hpackages)
        ];
      };

    });
in outputs
