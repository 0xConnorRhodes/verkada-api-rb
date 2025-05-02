{ stdenv, bundlerEnv, ruby }:
let
  gems = bundlerEnv {
    name = "httparty";
    inherit ruby_3_4;
    gemdir  = ./.;
  };
in stdenv.mkDerivation {
  name = "httparty";
  src = ./.;
  buildInputs = [gems ruby_3_4];
  installPhase = ''
    mkdir -p $out
    cp -r $src $out
  '';
}
