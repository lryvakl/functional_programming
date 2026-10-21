module Textbook.Parser
  ( parseText
  , tokenize
  ) where

import Data.Char (isAlphaNum, isSpace)
import Data.List (dropWhileEnd)
import Prelude hiding (Word)
import Textbook.Types

isWordChar :: Char -> Bool
isWordChar c = isAlphaNum c || c == '_'

isJoiner :: Char -> Bool
isJoiner = (`elem` ("-'’." :: String))

isPunctuationChar :: Char -> Bool
isPunctuationChar = (`elem` (".,;:!?…()[]{}\"'«»„“”‘’-—–" :: String))

isTerminal :: Token -> Bool
isTerminal = \case
  PunctuationToken (Punctuation c) -> c `elem` (".!?…" :: String)
  _ -> False

spanWord :: String -> (String, String)
spanWord = \case
  j : c : rest | isJoiner j && isWordChar c -> let (w, rest') = spanWord rest in (j : c : w, rest')
  c : rest | isWordChar c -> let (w, rest') = spanWord rest in (c : w, rest')
  rest -> ("", rest)

tokenize :: String -> [Token]
tokenize = \case
  [] -> []
  s@(c : rest)
    | isSpace c -> Space : tokenize (dropWhile isSpace rest)
    | isWordChar c -> let (w, rest') = spanWord s in WordToken (Word (map Symbol w)) : tokenize rest'
    | isPunctuationChar c -> PunctuationToken (Punctuation c) : tokenize rest
    | otherwise -> SymbolToken (Symbol c) : tokenize rest

splitSentences :: [Token] -> [[Token]]
splitSentences tokens = case break isTerminal tokens of
  ([], []) -> []
  (body, rest) ->
    let (terminals, rest') = span isTerminal rest
     in (body ++ terminals) : splitSentences rest'

trimSpaces :: [Token] -> [Token]
trimSpaces = dropWhileEnd (== Space) . dropWhile (== Space)

parseText :: String -> Text
parseText = Text . map Sentence . filter (not . null) . map trimSpaces . splitSentences . tokenize
