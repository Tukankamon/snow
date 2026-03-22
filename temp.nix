{
  inputs.nixpkgs.url = "nixpkgs/nixos-25.11";
  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    hpkgs = pkgs.haskellPackages;
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        ghc
        cabal-install
      ];
      shellHook = ''
      '';
    };
  };
}
