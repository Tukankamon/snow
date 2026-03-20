module Main (main) where

tab :: String
tab = "\t"

data Shell = Shell { packages :: [String], hook :: [String] } deriving (Show)
data Nixpkgs = Stable | Unstable

branchToString :: Nixpkgs -> String
branchToString br = case br of
  Stable -> "nixos-25.11"
  Unstable -> "nixos-unstable"

data Arch = X86 -- #TODO add more

archToString :: Arch -> String
archToString set = case set of
  X86 -> "x86_64-linux"

catListLn :: [String] -> String -> String
catListLn [] _ = ""
catListLn [x] prefix = prefix ++ x
catListLn (x:xs) prefix = prefix ++ x ++ "\n" ++ catListLn xs prefix

catDot :: [String] -> String
catDot [] = ""
catDot [x] = x
catDot (x:xs) = x ++ "." ++ catDot xs

generateList :: [String] -> String
generateList list = "[\n" ++ catListLn list tab ++ "\n];"

generateInline :: [String] -> String
generateInline list = "''\n" ++ catListLn list tab ++ "\n'';"

generateSet :: [String] -> String -> String
generateSet list suffix = "{\n" ++ catListLn list tab ++ "\n}" ++ suffix

generateHook :: [String] -> String
generateHook cmd = "shellHook = " ++ generateInline cmd

generateShell :: Shell -> Arch -> String
generateShell shell arch =
  catDot ["devShells", archToString arch, "default"] ++ " = pkgs.mkShell "
  ++ generateSet [ "packages = with pkgs; "
  ++ generateList (packages shell), generateHook (hook shell)] ";"

generateLetIn :: [String] -> Shell -> Arch -> String
generateLetIn definitions shell arch =
  "let\n" ++ catListLn definitions tab
  ++ "\nin\n" ++ generateSet [generateShell shell arch] ";"

generateOutputs :: [String] -> Shell -> Arch -> String
generateOutputs definitions shell arch = "outputs = \n"
  ++ catListLn ["{self, nixpkgs }:", generateLetIn definitions shell arch ] tab

generateFlake :: Nixpkgs -> [String] -> Shell -> Arch -> String
generateFlake branch definitions shell arch = generateSet [
  "inputs.nixpkgs.url = \"nixpkgs/" ++ branchToString branch ++ "\";",
  generateOutputs definitions shell arch ] ""

main :: IO ()
main = putStrLn $ generateFlake Stable definitions testShell X86 
  where
    definitions = [catDot ["pkgs = nixpkgs.legacyPackages", archToString X86] ++ ";"]
    testShell = Shell { packages = ["ghc"], hook = ["fish"] }
