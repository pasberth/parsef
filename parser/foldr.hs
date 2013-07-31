import Control.Arrow
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
      let exeproc = readProcess command cmdargs
      let f l | l `F.elem` sepmarks' = unlines >>> exeproc >>> fmap ((l :) . lines)
              | otherwise            = return . (l:)

      putStr =<< exeproc . unlines =<< foldrM f [] (lines contents)