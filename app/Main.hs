-- Copyright 2017 Bose Corporation.
-- This software is released under the 3-Clause BSD License.
-- The license can be viewed at https://github.com/Bose/Smudge/blob/master/LICENSE

module Main where

import Args(getAllOpt, getFileOpt)
import Args (
  Options(..),
  SystemOption(..),
  EnvmntOption(..),
  CommonOption(..),
  getAllOpt,
  getFileOpt,
  )
import Language.Smudge.Backends.Backend (generate, Config(..), defaultConfig)
import Language.Smudge.Semantics.Model (
  EnterExitState,
  Happening,
  passInitialState,
  passFullyQualify,
  passRename,
  passTagCategories,
  passWholeStateToGraph,
  QualifiedName,
  TaggedName,
  )
import Language.Smudge.Grammar (
  StateMachine,
  WholeState,
  )
import Language.Smudge.Semantics.Solver (
  SymbolTable,
  elaborateMono,
  elaboratePoly,
  )
import Language.Smudge.Parsers.Id (Identifier)
import Language.Smudge.Parsers.Smudge (smudge_file)
import Language.Smudge.Semantics.Alias (Alias, merge)
import Language.Smudge.Semantics.Basis (basisAlias, bindBasis)
import Language.Smudge.Passes.Passes (Severity(..), Fault(..), fatal)
import Language.Smudge.Passes (make_passes, name_passes, type_passes)
import Data.Graph.Extra

import Control.Monad (when)
import Control.Monad.Trans.Except (runExceptT)
import Control.Arrow (second)
import Control.Applicative ((<$>), (<*>))
import Text.Parsec (parse, eof)
import System.Environment (getArgs)
import System.FilePath (joinPath, takeFileName, dropFileName, normalise)
import System.Exit (exitFailure)
import Data.Graph.Inductive.PatriciaTree (Gr)
import Data.Either (lefts, rights, isLeft)
import Data.Map (fromList)
import Data.Monoid (mempty)

rename :: String -> Either String (QualifiedName, QualifiedName)
rename s = case map (second reads) $ reads s of
            [(a, [(b, "")])] -> Right (a, b)
            otherwise      -> Left s

processFile :: String -> [Options] -> IO ()
processFile fileName os = do
    compilationUnit <-
        if fileName == "-"
            then getContents
            else readFile fileName
    case parse (smudge_file <* eof) fileName compilationUnit of
        Left err -> print err >> report_failure 1
        Right (ps, sms) -> do
            os' <- getFileOpt ps
            let os'' = os' ++ os
            converted <- checkAndConvert sms os''
            make_output outputTarget os'' converted
    where outputTarget = normalise $ joinPath [(prefix os), takeFileName fileName]
          prefix [] = dropFileName fileName
          prefix ((SystemOption (OutDir p)):_) = p
          prefix (_:t) = prefix t

checkAndConvert :: [(StateMachine Identifier, [WholeState Identifier])] -> [Options] -> IO ([(StateMachine TaggedName, Gr EnterExitState Happening)], Alias QualifiedName, SymbolTable)
checkAndConvert sms os = do
    let rename_errors = lefts renames
    mapM (putStrLn . ("Parse error in rename flag: " ++)) rename_errors
    when (not $ null rename_errors) $ report_failure $ length rename_errors
    m sms
    where
        renames = map rename [r | EnvmntOption (Rename r) <- os]
        namespace = last $ "SMUDGE" : [n | EnvmntOption (Namespace n) <- os]
        aliases = merge (basisAlias namespace) $ fromList $ rights renames
        m sms = do
            let sms' = passInitialState sms
            let sms'' = passRename aliases $ passFullyQualify sms'
            let sms''' = passTagCategories sms''
            let fs = concat $ map name_passes sms'''
            mapM print fs
            when (any fatal fs) $ report_failure $ length fs

            let basis = bindBasis aliases $ map fst sms''
            let st = if elem (EnvmntOption (Strict True)) os
                     then elaborateMono basis sms'''
                     else elaboratePoly basis sms'''
            -- This is a bit of a hack around the definition of Passable
            let types = take 1 (zip (map fst sms''') (repeat st))
            let fs = concat $ map type_passes types
            mapM print fs
            when (any fatal fs) $ report_failure $ length fs

            let gs = passWholeStateToGraph sms'''
            let fs = concat $ map make_passes gs
            mapM print fs
            when (any fatal fs) $ report_failure $ length fs

            return (gs, aliases, st)

report_failure :: Int -> IO a
report_failure n = putStrLn ("Exiting with " ++ show n ++ " error" ++ (if n == 1 then "" else "s")) >> exitFailure

make_output :: String -> [Options] -> ([(StateMachine TaggedName, Gr EnterExitState Happening)], Alias QualifiedName, SymbolTable) -> IO ()
make_output fileName os gswst = do
    let noDebug = elem (CommonOption (Debug False)) os
    let logEvent = elem (CommonOption (LogEvent True)) os
    let dbgCfg = if noDebug then defaultConfig { debug=False } else defaultConfig
    let config = if logEvent then dbgCfg { logEvent=True } else dbgCfg
    let gvos = [a | GraphVizOption a <- os]
    gres <- runExceptT $ generate gvos config gswst fileName
    let csos = [a | CStaticOption a <- os]
    cres <- runExceptT $ generate csos config gswst fileName
    let fs = lefts [gres, cres]
    let outputNames = concat $ rights [gres, cres]
    mapM_ putStrLn $ do outputName <- outputNames
                        ["Wrote file \"" ++ outputName ++ "\""]
    mapM print fs
    when (any fatal fs) $ report_failure $ length fs

main = do
    args <- getArgs
    (os, (fileName:as)) <- getAllOpt args
    processFile fileName os
