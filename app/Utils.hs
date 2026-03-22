module Utils where

catListLn :: [String] -> String -> String
catListLn [] _ = ""
catListLn [x] prefix = prefix ++ x
catListLn (x:xs) prefix = prefix ++ x ++ "\n" ++ catListLn xs prefix

catDot :: [String] -> String
catDot [] = ""
catDot [x] = x
catDot (x:xs) = x ++ "." ++ catDot xs
