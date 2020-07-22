{-|
Module      : Analyser
Description : Calculates arity and statement count for FunctionData items
-}
module Analyser
    ( CSV
    , functionDataToCsv
    )
where

import           Data.List                      ( sortOn )
import           ASTProcessor                   ( FunctionData
                                                , filePath
                                                , lineNumber
                                                , name
                                                , arity
                                                , stmtsCount
                                                )
import           Numeric.Extra                  ( intToDouble )
import  Helpers  ( makeScaler )

type CSV = String

arityScalerMaker :: [FunctionData] -> (FunctionData -> Double)
arityScalerMaker = makeScaler (intToDouble . arity)

stmtsCountScalerMaker ::  [FunctionData] -> (FunctionData -> Double)
stmtsCountScalerMaker = makeScaler (intToDouble . stmtsCount)

-- | Converts a list of FunctionPairCompoundSimilarity into a single String, ready
-- | to be written as a csv file  (`,` as a column delimiter, `\n` as a row delimiter).
functionDataToCsv :: [FunctionData] -> CSV
functionDataToCsv fds =
    unlines
        $ (:) "Identifier,Arity,Statements Count,File Path"
        $ map
              (\fd -> name fd
                      ++ ","
                      ++ show (arity fd)
                      ++ ","
                      ++ show (stmtsCount fd)
                      ++ ","
                      ++ filePath fd
                      ++ ":"
                      ++ show (lineNumber fd)
              )
        $ sortOn (\fd -> -1 * (arityScaler fd + stmtsCountScaler fd)) fds
    where
        arityScaler = arityScalerMaker fds
        stmtsCountScaler = stmtsCountScalerMaker fds
