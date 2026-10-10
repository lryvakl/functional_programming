{-# LANGUAGE AllowAmbiguousTypes #-}

module Newspaper.Entity
  ( Key
  , Column (..)
  , Entity (..)
  , describe
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Database.MySQL.Simple.QueryResults (QueryResults)
import Newspaper.Field (RowParser, Value, display)

type Key = Int

data Column = Column
  { columnName :: Text
  , columnLabel :: Text
  }

class QueryResults a => Entity a where
  tableName :: Text
  entityTitle :: Text
  columns :: [Column]
  entityKey :: a -> Key
  fields :: a -> [Value]
  parser :: Key -> RowParser a

describe :: forall a. Entity a => a -> Text
describe e =
  "#" <> T.pack (show (entityKey e)) <> "  "
    <> T.intercalate " | " (zipWith pair (columns @a) (fields e))
  where
    pair c v = columnLabel c <> ": " <> display v
