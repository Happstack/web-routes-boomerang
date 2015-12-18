{ mkDerivation, base, boomerang, mtl, parsec, stdenv, text
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
}
