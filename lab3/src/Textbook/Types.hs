module Textbook.Types
  ( Symbol (..)
  , Word (..)
  , Punctuation (..)
  , Token (..)
  , Sentence (..)
  , Text (..)
  , HasWords (..)
  ) where

import Prelude hiding (Word)

newtype Symbol = Symbol Char
  deriving stock (Eq, Ord, Show)

newtype Word = Word [Symbol]
  deriving stock (Eq, Ord, Show)

newtype Punctuation = Punctuation Char
  deriving stock (Eq, Show)

data Token
  = WordToken Word
  | PunctuationToken Punctuation
  | SymbolToken Symbol
  | Space
  deriving stock (Eq, Show)

newtype Sentence = Sentence [Token]
  deriving stock (Eq, Show)

newtype Text = Text [Sentence]
  deriving stock (Eq, Show)

class HasWords a where
  wordsOf :: a -> [Word]

instance HasWords Token where
  wordsOf = \case
    WordToken w -> [w]
    _ -> []

instance HasWords Sentence where
  wordsOf (Sentence tokens) = concatMap wordsOf tokens

instance HasWords Text where
  wordsOf (Text sentences) = concatMap wordsOf sentences
