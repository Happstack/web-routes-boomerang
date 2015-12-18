{ nixpkgs ? import <nixpkgs> {}, compiler ? "default" }:

let

  inherit (nixpkgs) pkgs;

  f = { mkDerivation, base, boomerang, mtl, parsec, stdenv, text
      , web-routes
      }:
      mkDerivation {
        pname = "web-routes-boomerang";
        version = "0.28.4";
        src = ./.;
        libraryHaskellDepends = [
          base boomerang mtl parsec text web-routes
        ];
        description = "Library for maintaining correctness and composability of URLs within an application";
        license = stdenv.lib.licenses.bsd3;
      };

  haskellPackages = if compiler == "default"
                       then pkgs.haskellPackages
                       else pkgs.haskell.packages.${compiler};

  drv = haskellPackages.callPackage f {};

in

  if pkgs.lib.inNixShell then drv.env else drv
