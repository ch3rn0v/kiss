{-|
Module      : Analyser
Description : Calculates arity and statement count for FunctionData items
-}
module Analyser (CSV, functionDataToCsv) where

import Data.List (sortOn)
import Helpers (makeScaler)

import Numeric.Extra (intToDouble)

import ASTProcessor
       (FunctionData, arity, filePath, lineNumber, name,
        maxDepth, stmtsCount)

type CSV = String

arityScalerMaker :: [FunctionData] -> (FunctionData -> Double)
arityScalerMaker = makeScaler (intToDouble . arity)

depthScalerMaker :: [FunctionData] -> (FunctionData -> Double)
depthScalerMaker = makeScaler (intToDouble . maxDepth)

stmtsCountScalerMaker :: [FunctionData] -> (FunctionData -> Double)
stmtsCountScalerMaker = makeScaler (intToDouble . stmtsCount)

-- | Converts a list of FunctionPairCompoundSimilarity into a single String, ready
-- | to be written as a csv file  (`,` as a column delimiter, `\n` as a row delimiter).
functionDataToCsv :: [FunctionData] -> CSV
functionDataToCsv fds
  = unlines $
      (:) "Identifier,Arity,Max Depth,Statements Count,File Path" $
        map
          (\ fd -> name fd
                    ++ ","
                    ++ show (arity fd)
                    ++ ","
                    ++ show (maxDepth fd)
                    ++ ","
                    ++ show (stmtsCount fd)
                    ++ ","
                    ++ filePath fd
                    ++ ":"
                    ++ show (lineNumber fd))

          $ sortOn (\ fd -> -1 * ( arityScaler fd
                                 + depthScaler fd
                                 + stmtsCountScaler fd)) fds

  where arityScaler = arityScalerMaker fds
        depthScaler = depthScalerMaker fds
        stmtsCountScaler = stmtsCountScalerMaker fds
