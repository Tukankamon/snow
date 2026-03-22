module Main (main) where
import Config
import Utils
import System.Environment (getArgs)

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
