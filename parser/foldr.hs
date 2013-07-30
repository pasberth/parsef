import Control.Applicative
import Data.Foldable as F
import System.Exit
import System.Environment
import System.Process

getSepmarksByArgs :: [String] -> [String]
getSepmarksByArgs (('-':'@':sepmark):args) = sepmark : getSepmarksByArgs args
getSepmarksByArgs args                     = []

getCommandNameByArgs :: [String] -> Maybe String
getCommandNameByArgs (('-':'@':sepmark):args) = getCommandNameByArgs args
getCommandNameByArgs (name:args)              = Just name
getCommandNameByArgs []                       = Nothing

getCommandArgsByArgs :: [String] -> [String]
getCommandArgsByArgs (('-':'@':sepmark):args) = getCommandArgsByArgs args
getCommandArgsByArgs (name:args)              = args
getCommandArgsByArgs []                       = []

main = do
  args <- getArgs
  contents <- getContents 
  let sepmarks = getSepmarksByArgs args
  let command  = getCommandNameByArgs args
  let cmdargs  = getCommandArgsByArgs args

  case command of
    Nothing -> exitFailure
    Just command -> do
      let exeproc  = readProcess command cmdargs

      r <- foldrM (\l b -> if l `F.elem` sepmarks then (\b -> l : lines b) <$> exeproc (unlines b) else return (l:b)) [] (lines contents)
      r <- exeproc (unlines r)
      putStr r