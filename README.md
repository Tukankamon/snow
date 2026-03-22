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
Configuration is done following the suckless style of recompiling your changes directly into your program. Most configuration use cases should be configurable in Config.hs but of course as with any libre program you are free to change it as you wish. Because of this, snow doesn't need any external dependencies at build time other than ghc (or cabal for slightly more convenience)

The Config.hs file in this repo will have comments explaining each part and it is worthwhile checking the Utils.hs file as it has some helper functions that Config.hs makes use of

# TODO
- [ ] Specific language builder support (cargo, cabal etc)
- [x] Configuration file
    - With TOML or maybe an actual haskell file that gets compiled like xmonad / suckless ideals
