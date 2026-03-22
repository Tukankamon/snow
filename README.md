Simple nix flake boiler plate generator

# Usage
```
snow [LANGUAGE] > flake.nix
```

Will write nix flake boilerplate. It is not correctly formatted so alejandra is recommended

Currently available languages are:
    - Rust
    - Haskell
These are to fill out common dependencies like cargo and rustc for Rust
Setting the LANGUAGE field empty will default to a generic flake

# Configuration
Configuration is done following the suckless style of recompiling your changes directly into your program. Most configuration use cases should be configurable in Config.hs but of course as with any libre program you are free to change it as you wish. Because of this, snow doesn't need any external dependencies at build time other than ghc

The Config.hs file in this repo will have comments explaining each part and it is worthwhile checking the Utils.hs file as it has some helper functions that Config.hs makes use of

# Installation
## Flake
First add the input
```nix
# Flake.nix
inputs.snow.url = "git+https://codeberg.org/Tukankamon/snow";
```

Then add it to your configuration
```nix
# configuration.nix (or wherever)
{ inputs, pkgs, ...}: {
    environment.systemPackages = [
        (inputs.snow.packages.x86_64-linux.default.override {
            configFile = ./path/to/Config.hs;
        })
    ];
}
You ofcourse dont need to override it if you don't need to change the configuration
```

## Non-Flake
If you want to avoid cluttering your flake inputs or you simply don't use them you can create a nix derivation to build the program manually and add it to your environment packages:
```nix
environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      name = "snow";
      src = pkgs.fetchFromGitea {
        domain = "codeberg.org";
        owner = "Tukankamon";
        repo = "snow";
        rev = "c77a6d0418";
        sha256 = "sha256-ednbp/7NZvtyUr2yXgHWmfYKy3yiAVFdvT8rnZQtkFI=";
      };
      buildInputs = [ (pkgs.haskellPackages.ghcWithPackages (ps: [])) ];
      buildPhase = ''
        # Uncomment this line to change config file
        #cp ${./Config.hs} app/Config.hs

        # Add whatever compiler flags you want here doing 'make FLAGS="-02 -Wall"' (for example)
        make
      '';
      installPhase = ''
        mkdir -p $out/bin
        cp snow $out/bin/
      '';
    })
];
```

# TODO
- [ ] Specific language builder support (cargo, cabal etc)
- [ ] Figure out if cabal should be used or makefile/justfile with bare ghc
- [x] Configuration file
    - With TOML or maybe an actual haskell file that gets compiled like xmonad / suckless style
