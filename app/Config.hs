module Config where
import Utils
import System.Environment (getArgs)

-- Separator for indentations, could be changed to something like spaces
-- It is not perfect so it will probably need alejandra or any other formatter anyway
tab :: String
tab = "\t"

-- Default architecture to be used throughout the flake
defaultArch :: Arch
defaultArch = X86

-- Default branch to be used in the flake inputs
defaultBranch :: Nixpkgs
defaultBranch = Stable

-- List of languages that will need to be implemented later in the file
-- Note that they dont have to be actual languages, for example Default is
-- a "language" target that creates a general flake, you can do the same for any
-- wierd use case for flakes you might have
data Language = Default | Rust | Haskell | C

-- The branch to be used in the nixpkgs inputs
data Nixpkgs = Stable | Unstable

-- System architechture
data Arch = X86 -- #TODO add more

-- All the information that will actually get passed onto the builders
data Data = Data {arch :: Arch, lang :: Language, branch :: Nixpkgs}

-- Derived from Data and is the List of:
-- definitions: things like pkgs = nixpkgs.legacyPackages.system
-- packages: packages that will be in the nix shell after running nix develop
-- hook: Commands to be run immediately after entering the shell
-- other:: Literally anything else (mind that ";" is added automatically so no need for you to add it
  -- see how rust is implemented in fillConfig for an example
data Config  = Config { definitions :: [String], packages :: [String], hook :: [String], other :: [String] } deriving (Show)

-- Only the actual branch name is needed. For now, the link body is autocompleted in the code
branchToString :: Nixpkgs -> String
branchToString br = case br of
  Stable -> "nixos-25.11"
  Unstable -> "nixos-unstable"

-- Converts the architectures defined above to strings
archToString :: Arch -> String
archToString architechture = case architechture of
  X86 -> "x86_64-linux"

-- Returns the config data structure defined above based off of the language
fillConfig :: Data -> Config
fillConfig dat = case lang dat of
  Default -> Config {
    definitions = [pkgs],
    packages = [""],
    hook = ["fish"],
    other = [] }
  Rust -> Config {
    definitions = [pkgs],
    packages = ["cargo", "rustc", "rustfmt"],
    hook = [],
    -- env variable needed for lsp's and other things:
    -- https://www.youtube.com/watch?v=Ss1IXtYnpsg&t=187s
    other = ["env.RUST_SRC_PATH = \"${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}\""]}
  Haskell -> Config {
    definitions = [pkgs, hpkgs],
    packages = ["ghc", "cabal-install"],
    hook = [],
    other = [] }
  C -> Config {
    definitions = [pkgs],
    packages = ["make", "cmake", "gcc", "gdb"],
    hook = [],
    other = [] }
  where
    pkgs = catDot ["pkgs = nixpkgs.legacyPackages", archToString (arch dat)] ++ ";"
    hpkgs = "hpkgs = pkgs.haskellPackages;"

-- Actual argument parsing, add your own custom arguments as neeed
-- Takes in the generateFlake funtion defined in Main.hs, this is done to avoid cirular imports
parseArgs :: (Data -> String) -> IO String
parseArgs generator = do
  args <- getArgs
  -- #TODO parse architecture and branch, and make it case insensitive
  return $ case args of
    [] -> generator $ builder defaultArch Default defaultBranch
    ["rust"] -> generator $ builder defaultArch Rust defaultBranch
    ["haskell"] -> generator $ builder defaultArch Haskell defaultBranch
    ["c"] -> generator $ builder defaultArch C defaultBranch
    [x] -> "Unrecognized language: " ++ x
    _ -> "Too many arguments"
    where
    builder :: Arch -> Language -> Nixpkgs -> Data
    builder architecture language br =
      Data { arch = architecture, lang = language, branch = br }
