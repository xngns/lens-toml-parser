{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import           Control.Monad (unless)
import qualified Data.Map.Lazy as Map
import qualified Data.Text as T
import           Data.Text.IO (readFile)
import           Lens.Simple
import           Prelude hiding (readFile)
import           System.Exit (exitFailure)
import           Test.Dwergaz
import qualified TOML
import           TOML.Lens

readExample :: IO [(T.Text, TOML.Value)]
readExample = readExFile >>= parse >>= handleError
  where
    readExFile  = readFile "./example/example-v0.4.0.toml"
    parse       = pure . TOML.parseTOML
    handleError = either (error . show) pure

tableAt :: T.Text -> Map.Map T.Text TOML.Value -> Map.Map T.Text TOML.Value
tableAt k = views (at k . _Just . _Table) Map.fromList

test1 :: Map.Map T.Text TOML.Value -> Test
test1 kv = Expect "get key1" (==) expected actual
  where
    expected = [1, 2, 3]
    actual   = toListOf (at "key1" . _Just . _List . traverse . _Integer) (tableAt "array" kv)

tests :: Map.Map T.Text TOML.Value -> [Test]
tests kv = [test1] <*> [kv]

results :: Map.Map T.Text TOML.Value -> IO [Result]
results kv = pure (fmap runTest (tests kv))

main :: IO ()
main =  do
  ex <- readExample
  -- _  <- print (Map.fromList ex)
  rs <- results (Map.fromList ex)
  _  <- mapM_ print rs
  unless (all isPassed rs) exitFailure
