module Textbook.Analysis
  ( countLetter
  , sortByLetter
  ) where

import Data.Char (ord, toLower)
import Data.List (elemIndex, sortOn)
import Prelude hiding (Word)
import Textbook.Render (Render (..))
import Textbook.Types (Symbol (..), Word (..))

ukrainianAlphabet :: String
ukrainianAlphabet = "абвгґдеєжзиіїйклмнопрстуфхцчшщьюя"

collationKey :: Char -> (Int, Int)
collationKey c = maybe (0, ord lower) (1,) (elemIndex lower ukrainianAlphabet)
  where
    lower = toLower c

countLetter :: Char -> Word -> Int
countLetter letter (Word symbols) = length [() | Symbol c <- symbols, toLower c == toLower letter]

sortByLetter :: Char -> [Word] -> [Word]
sortByLetter letter = sortOn (\w -> (countLetter letter w, map collationKey (render w), render w))
