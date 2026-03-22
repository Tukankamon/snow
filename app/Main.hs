module Main (main) where

import System.Environment (getArgs)

tab :: String
tab = "\t"

data Language = Default | Rust | Haskell
data Config  = Config { definitions :: [String], packages :: [String], hook :: [String] } deriving (Show)
data Nixpkgs = Stable | Unstable
data Arch = X86 -- #TODO add more
data Data = Data {arch :: Arch, lang :: Language, branch :: Nixpkgs}

branchToString :: Nixpkgs -> String
branchToString br = case br of
  Stable -> "nixos-25.11"
  Unstable -> "nixos-unstable"

archToString :: Arch -> String
archToString architechture = case architechture of
  X86 -> "x86_64-linux"

catListLn :: [String] -> String -> String
catListLn [] _ = ""
catListLn [x] prefix = prefix ++ x
catListLn (x:xs) prefix = prefix ++ x ++ "\n" ++ catListLn xs prefix

catDot :: [String] -> String
catDot [] = ""
catDot [x] = x
catDot (x:xs) = x ++ "." ++ catDot xs

fillConfig :: Data -> Config
fillConfig dat = case lang dat of
  Default -> Config {
    definitions = [pkgs],
    packages = [""],
    hook = ["fish"] }
  Rust -> Config {
    definitions = [pkgs],
    packages = ["cargo", "rustc"],
    hook = [] }
  Haskell -> Config {
    definitions = [pkgs, hpkgs],
    packages = ["ghc", "cabal-install"],
    hook = [] }
  where
    pkgs = catDot ["pkgs = nixpkgs.legacyPackages", archToString (arch dat)] ++ ";"
    hpkgs = "hpkgs = pkgs.haskellPackages;"

generateList :: [String] -> String
generateList list = "[\n" ++ catListLn list tab ++ "\n];"

generateInline :: [String] -> String
generateInline [] = "''\n\t'';"
generateInline list = "''\n" ++ catListLn list tab ++ "\n'';"

generateSet :: [String] -> String -> String
generateSet list suffix = "{\n" ++ catListLn list tab ++ "\n}" ++ suffix

generateHook :: [String] -> String
generateHook cmd = "shellHook = " ++ generateInline cmd

generateShell :: Data -> String
generateShell dat = catDot ["devShells", archToString (arch dat), "default"]
  ++ " = pkgs.mkShell " ++ generateSet [ "packages = with pkgs; "
  ++ generateList (packages config), generateHook (hook config)] ";"
  where config = fillConfig dat

generateLetIn :: Data -> String
generateLetIn dat =
  "let\n" ++ catListLn (definitions (fillConfig dat)) tab
  ++ "\nin\n" ++ generateSet [generateShell dat] ";"

generateOutputs :: Data -> String
generateOutputs dat = "outputs = \n"
  ++ catListLn ["{self, nixpkgs }:", generateLetIn dat ] tab

generateFlake :: Data -> String
generateFlake dat = generateSet [
  "inputs.nixpkgs.url = \"nixpkgs/" ++ branchToString (branch dat) ++ "\";",
  generateOutputs dat ] ""

main :: IO ()
main = do
  args <- getArgs
  case args of -- #TODO parse architecture and branch, maybe use optparse-applicative lib
    [] -> putStrLn $ generateFlake $ Data { arch = X86, lang = Default, branch = Stable}
    ["rust"] -> putStrLn $
      generateFlake $ Data { arch = X86, lang = Rust, branch = Stable}
    ["haskell"] -> putStrLn $
      generateFlake $ Data { arch = X86, lang = Haskell, branch = Stable}
    [x] -> putStrLn $ "Unrecognized language: " ++ x
    _ -> putStrLn "Too many arguments"
