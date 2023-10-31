import System.Process.Typed

main :: IO ()
main = runProcess_ $ proc "guile" ["-c", "(display (+ 1 2)) (newline)" ]
