module Main (main) where
import Config

catListLn :: Int -> [String] -> String
catListLn indentLevel list =
  case (filter (`notElem` ["","\n"," "]) list, indentLevel) of
    ([], _) -> ""
    ([x], indentLevel) -> prefix ++ x
    ((x:xs), indentLevel) -> prefix ++ x ++ "\n" ++ catListLn indentLevel xs
  where prefix = nTabs indentLevel

catDot :: [String] -> String
catDot [] = ""
catDot [x] = x
catDot (x:xs) = x ++ "." ++ catDot xs

nTabs :: Int -> String
nTabs n = concat (replicate n tab)

generateList :: Int -> [String] -> String
generateList _ [] = "[];"
generateList indentLevel list =
  "[\n" ++ catListLn (indentLevel+1) list ++ "\n" ++ nTabs indentLevel ++ "];"

generateInline :: Int -> [String] -> String
generateInline indentLevel list =
  "''\n" ++ catListLn (indentLevel+1) list ++ nTabs indentLevel ++ "'';"

-- No ";" since some sets (e.g the one that wraps the whole file) dont have it
-- Add it explicitly if needed after each call
generateSet :: Int -> [String] -> String
generateSet _ [] = "{}"
generateSet indentLevel list =
  "{\n" ++ catListLn (indentLevel+1) list ++ "\n" ++ nTabs (indentLevel-1) ++ "}"

generateHook :: Int -> [String] -> String
generateHook indentLevel cmd = "shellHook = " ++ generateInline indentLevel cmd

generateShell :: Int -> Data -> String
generateShell indentLevel dat = catDot ["devShells", archToString (arch dat), "default"]
  ++ " = pkgs.mkShell "
  ++ generateSet (indentLevel+1) [
    "packages = with pkgs; " ++ generateList (indentLevel+2) (packages config),
    generateHook (indentLevel+2) (hook config),
    catListLn (indentLevel+2) (map (++ ";") (other config))
  ] ++ ";"
  where config = fillConfig dat

generateBuilder :: Int -> Data -> String
generateBuilder indentLevel dat = case builder $ fillConfig dat of
  Nothing -> ""
  Just buildr ->
    catDot ["packages", archToString (arch dat), "default"]
    ++ prefix buildr ++ " = " ++ generateSet indentLevel [
      "name = \"" ++ name buildr ++ "\";",
      "src = " ++ src buildr ++ ";",
      "buildInputs = " ++ generateList nextLvl (map (++ ";") (buildInputs buildr)),
      "nativeBuildInputs = " ++ generateList nextLvl (map (++ ";") (nativeBuildInputs buildr)),
      "buildPhase = " ++ generateInline nextLvl (buildPhase buildr),
      "installPhase = " ++ generateInline nextLvl (installPhase buildr),
      catListLn nextLvl (extra buildr)
    ] ++ ";"
  where nextLvl = indentLevel+1

generateLetIn :: Int -> Data -> String
generateLetIn indentLevel dat =
  nTabs indentLevel ++ "let\n" ++ catListLn nextLvl (definitions (fillConfig dat))
  ++ "\n" ++ nTabs indentLevel ++ "in "
  ++ generateSet nextLvl [
    generateShell (nextLvl+1) dat,
    generateBuilder (nextLvl+1) dat
  ] ++ ";"
  where nextLvl = indentLevel+1

generateOutputs :: Int -> Data -> String
generateOutputs indentLevel dat = "outputs = {self, nixpkgs }:\n"
  ++ generateLetIn indentLevel dat

generateInputs :: Int -> Data -> String
generateInputs indentLevel dat = case ins of
  [x] -> "inputs." ++ x
  _ -> "inputs = " ++ generateSet nextLvl ins ++ ";"
  where
    nextLvl = indentLevel + 1
    ins = map (++ ";") $ (input. fillConfig) dat

generateFlake :: Data -> String
generateFlake dat = generateSet 0 $ [generateInputs 1 dat, generateOutputs 1 dat]

main :: IO ()
main = parseArgs generateFlake >>= putStrLn
