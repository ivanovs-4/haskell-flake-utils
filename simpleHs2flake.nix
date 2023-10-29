# # This function returns a flake outputs-compatible schema.
{ lib, flake-utils }:
{ self
, src ? null
, nixpkgs
, systems ? flake-utils.lib.defaultSystems
, pname
, version ? "0.0.1"
, hpackages ? _: [ ]
, ghcOptions ? [
    "-O3"
    "-static"
    "-threaded"
    "-with-rtsopts=-N4 -A256m -H256m -K64m -AL256m -I0"
  ]
, tuneOutputs ? _: _: o: o
, runtimeDepsDefault ? _: []
, runtimeDeps ? _: {}
}:

let

  src' = builtins.filterSource
      (path: type: (type != "directory") && (nixpkgs.lib.hasSuffix ".hs" path))
      (if src != null then src else self);

  scripts = (with builtins; with nixpkgs.lib.attrsets; with nixpkgs.lib.strings;
    (map (x: removeSuffix ".hs" x."name")
      (filter (x: x."value" == "regular")
        (mapAttrsToList nameValuePair (readDir src'))
        )));

  withDefaultAllJoined = pkgs: kv: kv // {
    "default" = pkgs.symlinkJoin {
      name = pname;
      paths = builtins.attrValues kv;
    };
  };

  forEachToAttrs = xs: f: builtins.listToAttrs (map (x: {name = x; value = f x;}) xs);

  buildPackage = sname: pkgs: rtdeps: pkgs.stdenv.mkDerivation {
    inherit version;
    pname = sname;
    src = src';

    nativeBuildInputs = with pkgs; [ makeWrapper ];
    buildInputs = with pkgs; [ (haskellPackages.ghcWithPackages hpackages) ];

    buildPhase = ''
        ghc ${with nixpkgs.lib.strings; escapeShellArgs ghcOptions} "${sname}.hs"
    '';

    installPhase = ''
      mkdir -p $out/bin
      mv "${sname}" $out/bin/
    '';

    postFixup = if rtdeps == [] then "" else ''
      wrapProgram "$out/bin/${sname}" \
        --prefix PATH : ${pkgs.lib.makeBinPath rtdeps}
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

    in tuneOutputs system {inherit pkgs;} {

      packages =
        let allScripts =
          (forEachToAttrs scripts
              (sname:
                (buildPackage sname pkgs
                  (runtimeDepsDefault {inherit pkgs;}
                      ++ (nixpkgs.lib.attrsets.attrByPath [sname] []
                      (runtimeDeps {inherit pkgs;}))))));
        in
          with builtins;
          (if length scripts == 1
              then { "default" = head (attrValues allScripts); }
              else withDefaultAllJoined pkgs allScripts
          );

      apps = (forEachToAttrs scripts (sname: {
        type = "app";
        program = "${self.packages.${system}.${sname}}/bin/${sname}";
      }));

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs.haskellPackages; [
          (ghcWithPackages hpackages)
        ]
        ++ (runtimeDepsDefault {inherit pkgs;})
        ++ (with builtins; concatLists (attrValues (runtimeDeps {inherit pkgs;})))
        ;
      };

    });
in outputs
