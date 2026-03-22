A simple nix flake boiler plate generator

As opposed to something like [dev-templates](https://github.com/the-nix-way/dev-templates), this piece of software doesn't just copy from a folder of predesigned flakes rather it builds them up from scratch meaning it is much more customizable

# Usage
```
snow [LANGUAGE] > flake.nix
```

Will write nix flake boilerplate. Formatting is not perfect so a formatter like alejandra is recommended

Currently available languages are:

    - Rust
    - Haskell
    - C / Cpp
Run ```snow show``` to list all the available languages

These are to fill out common dependencies like cargo and rustc for Rust and builder functions as specified in [Config.hs](app/Config.hs)
Setting the LANGUAGE field empty will default to a generic flake

# Configuration
Configuration is done following the suckless style of recompiling your changes directly into your program but instead of writing actual patches, the configuration file is literaly a file that will get swapped out for the default [Config.hs](app/Config.hs). Most configuration use cases should be configurable in [Config.hs](app/Config.hs) but of course as with any libre program you are free to change it as you wish. Because of this, snow doesn't need any external dependencies at build time other than ghc

Configuring it in haskell results in a very configurable and extensible program as you can write any arbitrary amount of custom haskell logic but you can of course go the suckless way of patching it rather than editing the source code directly

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
```
You of course dont need to override it if you don't need to change the configuration

## Non-Flake
If you want to avoid cluttering your flake inputs you can create a nix derivation to build the program manually and add it to your environment packages:
```nix
environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      name = "snow";
      src = pkgs.fetchFromGitea {
        domain = "codeberg.org";
        owner = "Tukankamon";
        repo = "snow";
        rev = "c77a6d0418"; # Change this for the commit hash you want
        sha256 = pkgs.lib.fakeHash; # This will fail on build and thell you the correct hash
      };
      buildInputs = [ (pkgs.haskellPackages.ghcWithPackages (ps: [])) ];
      buildPhase = ''
        # Uncomment this line to change config file
        #cp ${./Config.hs} app/Config.hs

        # Add whatever compiler flags you want here with 'make FLAGS="-02 -Wall"' (for example)
        make
      '';
      installPhase = ''
        mkdir -p $out/bin
        cp build/snow $out/bin/
      '';
    })
];
```

# Adding a custom Language / Target
Follow these steps to add a custom language (or just a general template) to Config.hs

- Add it to the Language type definition
- Implement fillConfig, this just sets what the different parameters in the flake should be
- Implement parseArgs for it (follow the example of the other languages)

# TODO
- [x] Specific language builder support (cargo, cabal etc)
- [ ] Figure out if cabal should be used or makefile/justfile with bare ghc
- [x] Configuration file
    - With TOML or maybe an actual haskell file that gets compiled like xmonad / suckless style
- [ ] Alternate imput links
