{-# LANGUAGE OverloadedStrings #-}

import System.Process.Typed

main :: IO ()
main = runProcess_ "ls -lah"
