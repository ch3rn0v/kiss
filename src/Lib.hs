module Lib
    ( analyseJSONAst
    )
where

import           FileProcessor                  ( readJSONFile )
import           ASTProcessor                   ( parseRawJSONFile )
import           Analyser                       ( CSV
                                                , functionDataToCsv
                                                )

analyseJSONAst :: FilePath -> IO (Either String CSV)
analyseJSONAst path = do
    rawJSONFile <- readJSONFile path
    let parsedJSONFile = parseRawJSONFile rawJSONFile
    case parsedJSONFile of
        (Left errorMessage) -> return $ Left errorMessage
        (Right functionData) ->
            return
                $ Right
                $ functionDataToCsv functionData
