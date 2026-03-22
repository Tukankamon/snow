module Main (main) where
import Config
import Utils

generateList :: [String] -> String
generateList list = "[\n" ++ catListLn list tab ++ "\n];"

generateInline :: [String] -> String
generateInline [] = "''\n" ++ tab ++ "'';"
generateInline list = "''\n" ++ catListLn list tab ++ "\n'';"

-- No ";" since some sets (e.g the one that wraps the whole file) dont have it
-- Add it explicitly if needed after each call
generateSet :: [String] -> String
generateSet list = "{\n" ++ catListLn list tab ++ "\n}"

generateHook :: [String] -> String
generateHook cmd = "shellHook = " ++ generateInline cmd

generateShell :: Data -> String
generateShell dat = catDot ["devShells", archToString (arch dat), "default"]
  ++ " = pkgs.mkShell "
  ++ generateSet [
    "packages = with pkgs; " ++ generateList (packages config),
    generateHook (hook config)
  ] ++ ";"
  ++ catListLn (map (++ ";") (other config)) ""
  where config = fillConfig dat

generateLetIn :: Data -> String
generateLetIn dat =
  "let\n" ++ catListLn (definitions (fillConfig dat)) tab
  ++ "\nin\n" ++ generateSet [generateShell dat] ++ ";"

generateOutputs :: Data -> String
generateOutputs dat = "outputs = \n"
  ++ catListLn ["{self, nixpkgs }:", generateLetIn dat ] tab

generateFlake :: Data -> String
generateFlake dat = generateSet [
  "inputs.nixpkgs.url = \"nixpkgs/" ++ branchToString (branch dat) ++ "\";",
  generateOutputs dat ]

main :: IO ()
main = parseArgs generateFlake >>= putStrLn

