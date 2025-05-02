{ pkgs ? import <nixpkgs> { } }:
with pkgs;
with stdenv;
let
  httparty = bundlerEnv {
    name = "httparty";
    ruby = ruby_3_4;
    gemdir = ./.nix;
  };
in mkShell {
  name = "bundler-shell";
  buildInputs = [httparty bundix ruby_3_4];
  packages = with pkgs; [ 
    rubyPackages_3_4.pry
  ];
}

