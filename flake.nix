{
  description = "A flake with a multi-arch devShell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }:
  let
    supportedSystems = [ "aarch64-darwin" "x86_64-linux" ];

    # Obtain 'lib' from any one import (arch doesn't matter for lib)
    lib = (import nixpkgs { system = "x86_64-linux"; }).lib;

    makeShell = system:
      let
        pkgs = import nixpkgs { inherit system; };

        secrets = import ./tests/secrets.nix;

        ruby = pkgs.ruby_3_4;

	# package containing all gems defined in .nix/Gemfile
        rubyEnv = pkgs.bundlerEnv {
          name = "rubyEnv";
          ruby = ruby;
          gemdir = ./.nix;
        };
      in
      {
        # default devShell
        default = pkgs.mkShell {
          buildInputs = with pkgs; [ 
	    bashInteractive # needed for vscode
            ruby
            rubyEnv
          ];

          packages = with pkgs; [ 
            rubyPackages_3_4.pry
          ];

          shellHook = ''
            echo "This shell is for: ${system}"
          '';

          # ENV
          VAR1 = "123";
          VAR2 = "456";
          HELLO = secrets.hello;
        };
      };
  in
  {
    devShells = lib.genAttrs supportedSystems (system: makeShell system);
  };
}
