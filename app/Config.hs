module Config where
import System.Environment (getArgs)

-- Separator for indentations, could be changed to something like spaces
-- It is not perfect so it will probably need alejandra or any other formatter anyway
tab :: String
tab = "  "
--tab = "\t"

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

-- Package builders, for example mkDerivation
-- prefix: the part that goes at the beggining: eg "pkgs.mkDerivation"
-- name: name of the executable, best to leave blank
-- src: path to the code #TODO add fetch from github
-- buildInputs, nativeBuildInputs are the same as in Nix
-- buildPhase, installPhase: Commands to be run for each phase
-- extra: any other language-specific parameters (for an example look at rust's implementation in fillConfig)
data Builder = Builder {
  prefix :: String,
  name :: String,
  src :: String,
  buildInputs :: [String],
  nativeBuildInputs :: [String],
  buildPhase :: [String],
  installPhase :: [String],
  extra :: [String]
} deriving (Show)

-- Derived from Data and is the List of:
-- definitions: things like pkgs = nixpkgs.legacyPackages.system
-- builder: builder to use based on the language
-- packages: packages that will be in the nix shell after running nix develop
-- hook: Commands to be run immediately after entering the shell
-- other:: Literally anything else inside the shell (mind that ";" is added automatically so no need for you to add it
  -- see how rust is implemented in fillConfig for an example
data Config  = Config {
  definitions :: [String],
  builder :: Maybe Builder,
  packages :: [String],
  hook :: [String],
  other :: [String]
} deriving (Show)

-- Default builder, can be set to none if you don't want one. This will simply not generate it in the flake
defaultBuilder :: Maybe Builder
-- defaultBuilder = None
defaultBuilder = Just Builder {
  prefix = "pkgs.mkDerivation",
  name = "",
  src = "./.",
  buildInputs = [],
  nativeBuildInputs = [],
  buildPhase = [],
  installPhase = [],
  extra = []
}


-- Example for a rust cargo builder
cargoBuilder :: Maybe Builder
cargoBuilder = Just Builder {
  prefix = "pkgs.rustPlatform.buildRustPackage",
  name = "",
  src = "./.",
  buildInputs = [],
  nativeBuildInputs = [],
  buildPhase = [],
  installPhase = [],
  extra = ["cargoHash = pkgs.lib.fakeHash;"]
};

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
    builder = defaultBuilder,
    packages = [],
    hook = ["fish"],
    other = [] }
  Rust -> Config {
    definitions = [pkgs],
    builder = cargoBuilder,
    packages = ["cargo", "rustc", "rustfmt"],
    hook = [],
    -- env variable needed for lsp's and other things:
    -- https://www.youtube.com/watch?v=Ss1IXtYnpsg&t=187s
    other = ["env.RUST_SRC_PATH = \"${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}\""]}
  Haskell -> Config {
    definitions = [pkgs, hpkgs],
    builder = defaultBuilder,
    packages = ["ghc", "cabal-install"],
    hook = [],
    other = [] }
  C -> Config {
    definitions = [pkgs],
    builder = defaultBuilder,
    packages = ["make", "cmake", "gcc", "gdb"],
    hook = [],
    other = [] }
  where
    pkgs = "pkgs = nixpkgs.legacyPackages" ++ archToString (arch dat) ++ ";"
    hpkgs = "hpkgs = pkgs.haskellPackages;"

-- Actual argument parsing, add your own custom arguments as neeed
-- Takes in the generateFlake funtion defined in Main.hs, this is done to avoid cirular imports
parseArgs :: (Data -> String) -> IO String
parseArgs generator = do
  args <- getArgs
  -- #TODO parse architecture and branch, and make it case insensitive
  return $ case args of
    [] -> fillData defaultArch Default defaultBranch
    ["rust"] -> fillData defaultArch Rust defaultBranch
    ["haskell"] -> fillData defaultArch Haskell defaultBranch
    ["c"] -> fillData defaultArch C defaultBranch
    [x] -> "Unrecognized language: " ++ x
    _ -> "Too many arguments"
    where
    fillData :: Arch -> Language -> Nixpkgs -> String
    fillData architecture language br =
      generator $ Data { arch = architecture, lang = language, branch = br }
