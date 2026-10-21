module Main (main) where

import Control.Monad (when)
import Data.Char (isLetter)
import Data.List (nub)
import GHC.IO.Encoding (setLocaleEncoding, utf8)
import Options.Applicative
import Text.Printf (printf)
import Textbook.Analysis (countLetter, sortByLetter)
import Textbook.Parser (parseText)
import Textbook.Render (Render (..))
import Textbook.Types (HasWords (..))

data Options = Options FilePath Char Bool Bool

options :: Parser Options
options =
  Options
    <$> strArgument (metavar "FILE" <> help "Textbook file")
    <*> option (maybeReader letter) (long "letter" <> short 'l' <> metavar "CHAR" <> help "Letter to count")
    <*> switch (long "unique" <> short 'u' <> help "Remove duplicate words")
    <*> switch (long "show-text" <> short 's' <> help "Print normalized text")
  where
    letter = \case
      [c] | isLetter c -> Just c
      _ -> Nothing

main :: IO ()
main = do
  setLocaleEncoding utf8
  Options path letter unique showText <-
    execParser (info (options <**> helper) (fullDesc <> progDesc "Sort textbook words by occurrences of a letter"))
  text <- parseText <$> readFile path
  when showText $ putStrLn (render text)
  let ws = (if unique then nub else id) (wordsOf text)
  mapM_ (\w -> printf "%3d  %s\n" (countLetter letter w) (render w)) (sortByLetter letter ws)
