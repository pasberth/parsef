import Control.Applicative
import Data.Foldable as F
import System.Exit
import System.Environment
import System.Process

data Args = Args {
  sepmarks    :: [String]
, commandName :: Maybe String
, commandArgs :: [String]
}

parseArgs :: [String] -> Args
parseArgs (('-':'@':sepmark):args) = let x = parseArgs args in x { sepmarks = sepmark : sepmarks x }
parseArgs (name:args)              = let x = parseArgs args in x { commandName = Just name, commandArgs = args }
parseArgs []                       = Args [] Nothing []

main = do
  args <- parseArgs <$> getArgs
  let sepmarks' = sepmarks args
  let cmdargs   = commandArgs args
  contents <- getContents 

  case commandName args of
    Nothing -> exitFailure
    Just command -> do
      let exeproc  = readProcess command cmdargs

      r <- foldrM (\l b -> if l `F.elem` sepmarks' then (\b -> l : lines b) <$> exeproc (unlines b) else return (l:b)) [] (lines contents)
      r <- exeproc (unlines r)
      putStr r