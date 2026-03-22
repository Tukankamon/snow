module Utils where

catListLn :: [String] -> String -> String
catListLn [] _ = ""
catListLn [x] indent = indent ++ x
catListLn (x:xs) indent = indent ++ x ++ "\n" ++ catListLn xs indent

catDot :: [String] -> String
catDot [] = ""
catDot [x] = x
catDot (x:xs) = x ++ "." ++ catDot xs
