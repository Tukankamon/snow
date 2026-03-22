{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    hpkgs = pkgs.haskellPackages;

    # Does it make more sense to use cabal?
    mkSnow = { configFile ? null }: pkgs.stdenv.mkDerivation {
      name = "snow";
      src = ./.;
      buildInputs = [ (pkgs.haskellPackages.ghcWithPackages (ps: [])) ];
      buildPhase = ''
        ${if configFile != null then "cp ${configFile} app/Config.hs" else ""}
        make # This might change for cabal
      '';
      installPhase = ''
        mkdir -p $out/bin
        cp build/snow $out/bin
      '';
    };
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        ghc # Compiler
        fish # Better than bash (default shell)
        cabal-install
        #hpkgs.HUnit
      ];
      shellHook = ''
        fish
      '';
    };

    packages.x86_64-linux.default = pkgs.lib.makeOverridable mkSnow {};

    /*
    packages."x86_64-linux".default =
      hpkgs.callCabal2nix "snow" ./. {};
    */
  };
}
