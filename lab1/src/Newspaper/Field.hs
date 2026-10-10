module Newspaper.Field
  ( FieldValue (..)
  , Value (..)
  , RowParser
  , field
  , runRowParser
  , toAction
  , display
  , parseEnum
  ) where

import Control.Monad.State.Strict (StateT, evalStateT, get, lift, put)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (Day, defaultTimeLocale, parseTimeM)
import Database.MySQL.Simple.Param (Action, Param (..))
import Text.Read (readMaybe)

class Param f => FieldValue f where
  parseValue :: Text -> Either Text f
  showValue :: f -> Text

instance FieldValue Text where
  parseValue t
    | T.null t = Left "значення не може бути порожнім"
    | otherwise = Right t
  showValue = id

instance FieldValue Int where
  parseValue t = maybe (Left ("очікується ціле число: " <> t)) Right (readMaybe (T.unpack t))
  showValue = T.pack . show

instance FieldValue Day where
  parseValue t =
    maybe (Left ("очікується дата у форматі YYYY-MM-DD: " <> t)) Right $
      parseTimeM True defaultTimeLocale "%F" (T.unpack t)
  showValue = T.pack . show

parseEnum :: (Bounded e, Enum e, FieldValue e) => Text -> Either Text e
parseEnum t =
  maybe (Left ("допустимі значення: " <> T.intercalate ", " (map showValue options))) Right $
    lookup (T.toLower t) [(showValue o, o) | o <- options]
  where
    options = [minBound .. maxBound]

data Value = forall f. FieldValue f => Value f

toAction :: Value -> Action
toAction (Value v) = render v

display :: Value -> Text
display (Value v) = showValue v

newtype RowParser a = RowParser (StateT [Text] (Either Text) a)
  deriving newtype (Functor, Applicative, Monad)

field :: FieldValue f => RowParser f
field = RowParser $ get >>= \case
  t : rest -> put rest >> lift (parseValue t)
  [] -> lift (Left "недостатньо значень")

runRowParser :: RowParser a -> [Text] -> Either Text a
runRowParser (RowParser p) = evalStateT p
