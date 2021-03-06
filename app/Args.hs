-- Copyright 2017 Bose Corporation.
-- This software is released under the 3-Clause BSD License.
-- The license can be viewed at https://github.com/Bose/Smudge/blob/master/LICENSE

module Args (
    Options(..),
    SystemOption(..),
    EnvmntOption(..),
    CommonOption(..),
    getAllOpt,
    getFileOpt
) where

import System.Console.GetOpt.Extra (usageInfo, getOpt, OptDescr(..), ArgDescr(..), ArgOrder(Permute))
import PackageInfo (version, buildCommit, appName, author, synopsis)
import Language.Smudge.Backends.Backend (options)
import Language.Smudge.Backends.GraphViz (GraphVizOption(..))
import Language.Smudge.Backends.CStatic (CStaticOption(..))

import System.Exit (exitSuccess, exitFailure)

data SystemOption = Version
                  | Help
                  | OutDir FilePath
    deriving (Show, Eq)

data EnvmntOption = Strict Bool
                  | Namespace String
                  | Rename String
    deriving (Show, Eq)

data CommonOption = LogEvent Bool |
                    Debug Bool
    deriving (Show, Eq)

header :: String
header = "Usage: " ++ appName ++ " [OPTIONS] file\n" ++
         synopsis ++ "\n" ++
         "Written by " ++ author ++ "\n"

sysopts :: [OptDescr SystemOption]
sysopts = [Option ['v'] ["version"] (NoArg Version) "Version information.",
           Option ['h'] ["help"] (NoArg Help) "Print this message.",
           Option []    ["outdir"] (ReqArg OutDir "DIR") "Output directory."]

envopts :: [OptDescr EnvmntOption]
envopts = [Option []    ["[no-]strict"] (BoolArg Strict) "[DON'T] Require all types to match strictly",
           Option []    ["namespace"] (ReqArg Namespace "NEW") "Replace namespace.",
           Option []    ["rename"] (ReqArg Rename "\"OLD NEW\"") "Replace identifier."]

cmnopts :: [OptDescr CommonOption]
cmnopts = [Option []    ["[no-]logevent"] (BoolArg LogEvent) "[DON'T] Enable event tracing.",
           Option []    ["[no-]debug"] (BoolArg Debug) "[DON'T] Generate debugging information."]

deprecated_c_no_debug :: [OptDescr CommonOption]
deprecated_c_no_debug =
          [Option []    ["no-debug"] (BoolArg Debug) "[DEPRECATED] Don't generate debugging information."]

data Options = SystemOption SystemOption | EnvmntOption EnvmntOption | CommonOption CommonOption | GraphVizOption GraphVizOption | CStaticOption CStaticOption
    deriving (Show, Eq)

all_opts :: [OptDescr Options]
all_opts = [Subcommand "" SystemOption sysopts] ++ fileopts

fileopts :: [OptDescr Options]
fileopts = [Subcommand "" EnvmntOption envopts,
            Subcommand "" CommonOption cmnopts,
            Subcommand "c" CommonOption deprecated_c_no_debug,
            (Subcommand <$> fst <*> return CStaticOption <*> snd) options,
            (Subcommand <$> fst <*> return GraphVizOption <*> snd) options]

printUsage :: IO ()
printUsage = putStr (usageInfo header all_opts)

printVersion :: IO ()
printVersion = putStrLn (appName ++ " version: " ++ version)
            >> putStrLn ("build commit: " ++ buildCommit)

getAllOpt :: [String] -> IO ([Options], [String])
getAllOpt args =
    case getOpt Permute all_opts args of
        (os, _, [])
            | elem (SystemOption Help) os -> printUsage >> exitSuccess
            | elem (SystemOption Version) os -> printVersion >> exitSuccess
        (_, fs, es)
            | null fs -> putStrLn "No input files" >> putStr (concat es) >> printUsage >> exitFailure
            | not $ null es -> putStr (concat es) >> printUsage >> exitFailure
        (os, fs, _) -> return (os, fs)

getFileOpt :: [[String]] -> IO [Options]
getFileOpt argss =
    let flatten (a, b, c) = (concat a, concat b, concat c)
    in  case flatten $ unzip3 $ map (getOpt Permute fileopts) argss of
            (os, [], []) -> return os
            (_, fs, es) -> do putStr (concat es)
                              mapM (putStrLn . ("unrecognized argument `" ++) . (++ "'")) fs
                              exitFailure
