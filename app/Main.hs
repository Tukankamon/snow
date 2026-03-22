module Main (main) where
import Config
import Utils

generateList :: [String] -> String
generateList [] = "[];"
generateList list = "[\n" ++ catListLn list tab ++ "\n];"

generateInline :: [String] -> String
generateInline [] = "''\n" ++ tab ++ "'';"
generateInline list = "''\n" ++ catListLn list tab ++ "\n'';"

-- No ";" since some sets (e.g the one that wraps the whole file) dont have it
-- Add it explicitly if needed after each call
generateSet :: [String] -> String
generateSet [] = "{}"
generateSet list = "{\n" ++ catListLn list tab ++ "\n}"

generateHook :: [String] -> String
generateHook cmd = "shellHook = " ++ generateInline cmd

generateShell :: Data -> String
generateShell dat = catDot ["devShells", archToString (arch dat), "default"]
  ++ " = pkgs.mkShell "
  ++ generateSet [
    "packages = with pkgs; " ++ generateList (packages config),
    generateHook (hook config),
    catListLn (map (++ ";") (other config)) ""
  ] ++ ";"
  where config = fillConfig dat

generateBuilder :: Data -> String
generateBuilder dat = case builder $ fillConfig dat of
  Nothing -> ""
  Just buildr ->
    catDot ["packages", archToString (arch dat), "default"]
    ++ prefix buildr ++ " = " ++ generateSet [
      "name = \"" ++ name buildr ++ "\";",
      "src = " ++ src buildr ++ ";",
      "buildInputs = " ++ generateList (map (++ ";") (buildInputs buildr)),
      "nativeBuildInputs = " ++ generateList (map (++ ";") (nativeBuildInputs buildr)),
      "buildPhase = " ++ generateInline (buildPhase buildr),
      "installPhase = " ++ generateInline (installPhase buildr),
      catListLn (extra buildr) ""
    ] ++ ";"

generateLetIn :: Data -> String
generateLetIn dat =
  "let\n" ++ catListLn (definitions (fillConfig dat)) tab
  ++ "\nin\n" ++ generateSet [generateShell dat, generateBuilder dat] ++ ";"

generateOutputs :: Data -> String
generateOutputs dat = "outputs = \n"
  ++ catListLn ["{self, nixpkgs }:", generateLetIn dat ] tab

generateFlake :: Data -> String
generateFlake dat = generateSet [
  "inputs.nixpkgs.url = \"nixpkgs/" ++ branchToString (branch dat) ++ "\";",
  generateOutputs dat ]

main :: IO ()
main = parseArgs generateFlake >>= putStrLn

