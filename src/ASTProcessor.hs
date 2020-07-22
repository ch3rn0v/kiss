{-# LANGUAGE TupleSections #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

{-|
Module      : ASTProcessor
Description : Parses AST related data from .json files

Parses AST that is output by semantic library
(https://github.com/github/semantic/) in .json format.
-}
module ASTProcessor
       (parseRawJSONFile, FunctionData, Arity, StmtCount, filePath, lineNumber,
        name, arity, stmtsCount)
       where

import Control.Lens ((^?), cosmos, filtered, toListOf)
import Data.Aeson
import Data.Aeson.Lens (_Object, _String, key, nonNull)
import Data.Aeson.Types (Parser, parseEither)

import Data.Either (rights)

import Data.HashMap.Strict (keys)
import qualified Data.IntMap.Strict as IM (IntMap, elems, fromListWith)

import Data.Maybe (fromJust, isJust)
import Data.Text (Text)
import Data.Text.Lazy (pack)
import Data.Text.Lazy.Encoding (encodeUtf8)

import FileProcessor (RawJSONFile(RawJSONFile))

type DepthStatementData = (Int, [Text])

type LineNumber = Int

type Language = String

type FunctionIdentifier = String

type Arity = Int

type StmtCount = Int

type RawStatementsData = IM.IntMap [Text]

data FunctionData = FunctionData { filePath :: FilePath
                                 , lineNumber :: LineNumber
                                 , language :: Language
                                 , name :: FunctionIdentifier
                                 , arity :: Arity
                                 , stmtsCount :: StmtCount }
                    deriving Show

data TreeData = TreeData { rootNode :: Value
                         , treeFilePath :: FilePath
                         , treeLanguage :: Language }
                deriving Show

isKeyPresent :: Text -> Value -> Bool
isKeyPresent keyName v = isJust $ v ^? (key keyName . nonNull)

isTree :: Value -> Bool
isTree = isKeyPresent "tree"

isFunction :: Value -> Bool
isFunction v = v ^? (key "term" . _String) == Just "Function"

getAllElements :: (Value -> Bool) -> Value -> [Object]
getAllElements filterFn = toListOf (cosmos . filtered filterFn . _Object)

getAllFunctions :: Value -> [Object]
getAllFunctions = getAllElements isFunction

getAllTrees :: Value -> [Object]
getAllTrees = getAllElements isTree

-- | Recursively parses the given object and all its descendants,
-- | building a list of (depth, [termName]) items.
getAllStatements ::
                 Int
                 -> Object
                 -> Parser [DepthStatementData]
                 -> Parser [DepthStatementData]
getAllStatements depth stmtNode parserSDs
  = do (curTermName :: Maybe Text) <- stmtNode .:? "term"
       let curTerm = [(depth, [fromJust curTermName]) | isJust curTermName]

       let nodeKeys = keys stmtNode
       let (innerNodes :: [Object])
             = rights $ map (parseEither (\ k -> stmtNode .: k)) nodeKeys
       let (innerNodeArrays :: [[Object]])
             = rights $ map (parseEither (\ k -> stmtNode .: k)) nodeKeys
       let allInnerNodes = innerNodes ++ concat innerNodeArrays

       fmap concat $
         sequence $
           parserSDs :
             return curTerm :
               map
                 (\ nodeObject ->
                    getAllStatements (depth + 1) nodeObject $ return [])

                 allInnerNodes

parseAllStatements :: [Object] -> [DepthStatementData]
parseAllStatements
  = concat .
      rights . map (parseEither (\ n -> getAllStatements 1 n $ return []))

parseFunctionObject :: FilePath -> Language -> Object -> Parser FunctionData
parseFunctionObject path _language o
  = do sourceSpan <- o .: "sourceSpan"
       [oLineNumber, _] <- sourceSpan .: "start"
       functionName <- o .: "functionName"
       _name <- functionName .: "name"
       (parameters :: [Value]) <- o .: "functionParameters"
       body <- o .: "functionBody"
       (outerStatements :: [Object]) <- body .: "statements"

       let (allStatements :: [DepthStatementData])
             = parseAllStatements outerStatements
       let (statementsDepthMap :: RawStatementsData)
             = IM.fromListWith (++) allStatements

       return $
         FunctionData path oLineNumber _language _name (length parameters)
           (length $ concat $ IM.elems statementsDepthMap)

parseTreeFunctions :: TreeData -> [Either String FunctionData]
parseTreeFunctions (TreeData _rootNode _treeFilePath _treeLanguage)
  = map (parseEither $ parseFunctionObject _treeFilePath _treeLanguage)
      (getAllFunctions _rootNode)

parseTreeObject :: Object -> Parser TreeData
parseTreeObject o
  = do (_rootNode :: Value) <- o .: "tree"
       _treeFilePath <- o .: "path"
       _treeLanguage <- o .: "language"

       return $ TreeData _rootNode _treeFilePath _treeLanguage

-- | Given `RawJSONFile`, tries to parse its `contents`.
-- | Returns either an error's description, or `ParsedFiles`.
parseRawJSONFile :: RawJSONFile -> Either String [FunctionData]
parseRawJSONFile (RawJSONFile _ contents)
  = let decodedJSON = eitherDecode $ encodeUtf8 $ pack contents in
      case decodedJSON of
          (Left errorMessage) -> Left errorMessage
          (Right _rootNode) -> Right $
                                rights $
                                  concatMap parseTreeFunctions $
                                    rights $
                                      map (parseEither parseTreeObject) $
                                        getAllTrees _rootNode
