module Textbook.Render (Render (..)) where

import Prelude hiding (Word)
import Textbook.Types

class Render a where
  render :: a -> String

instance Render Symbol where
  render (Symbol c) = [c]

instance Render Word where
  render (Word symbols) = concatMap render symbols

instance Render Punctuation where
  render (Punctuation c) = [c]

instance Render Token where
  render = \case
    WordToken w -> render w
    PunctuationToken p -> render p
    SymbolToken s -> render s
    Space -> " "

instance Render Sentence where
  render (Sentence tokens) = concatMap render tokens

instance Render Text where
  render (Text sentences) = unlines (map render sentences)
