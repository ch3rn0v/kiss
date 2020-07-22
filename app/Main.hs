module Main where

import Lib (analyseJSONAst)
import System.Environment (getArgs)

main :: IO ()
main
  = do args <- getArgs
       if length args < 2 then
         error
           "\n\nERROR:\nThe path to the json file \
           \or the path to the output file was not \
           \provided. Please provide it.\n"
         else
         let pathToRead = head args
             pathToWrite = args !! 1
           in
           do analysisResult <- analyseJSONAst pathToRead
              case analysisResult of
                  (Left errorMessage) -> putStrLn errorMessage
                  (Right analysisResultCSV) -> writeFile pathToWrite
                                                 analysisResultCSV
              putStrLn "\nDone."
