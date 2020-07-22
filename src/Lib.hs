module Lib (analyseJSONAst) where

import ASTProcessor (parseRawJSONFile)
import Analyser (CSV, functionDataToCsv)
import FileProcessor (readJSONFile)

analyseJSONAst :: FilePath -> IO (Either String CSV)
analyseJSONAst path
  = do rawJSONFile <- readJSONFile path
       let parsedJSONFile = parseRawJSONFile rawJSONFile
       case parsedJSONFile of
           (Left errorMessage)  -> return $ Left errorMessage
           (Right functionData) -> return $ Right $ functionDataToCsv functionData
