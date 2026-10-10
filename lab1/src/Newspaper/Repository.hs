{-# LANGUAGE AllowAmbiguousTypes #-}

module Newspaper.Repository
  ( findAll
  , findById
  , insert
  , update
  , remove
  ) where

import Data.Maybe (listToMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Database.MySQL.Simple (Connection, Only (..), execute, insertID, query, query_)
import Database.MySQL.Simple.Types (Query (..))
import Newspaper.Entity (Column (..), Entity (..), Key)
import Newspaper.Field (Value (..), toAction)

sql :: [Text] -> Query
sql = Query . encodeUtf8 . T.unwords

commaSep :: [Text] -> Text
commaSep = T.intercalate ", "

columnNames :: forall a. Entity a => [Text]
columnNames = map columnName (columns @a)

selectFrom :: forall a. Entity a => [Text]
selectFrom = ["SELECT", commaSep ("id" : columnNames @a), "FROM", tableName @a]

byId :: [Text]
byId = ["WHERE id = ?"]

findAll :: forall a. Entity a => Connection -> IO [a]
findAll conn = query_ conn (sql (selectFrom @a ++ ["ORDER BY id"]))

findById :: forall a. Entity a => Connection -> Key -> IO (Maybe a)
findById conn k = listToMaybe <$> query conn (sql (selectFrom @a ++ byId)) (Only k)

insert :: forall a. Entity a => Connection -> a -> IO Key
insert conn e = do
  _ <- execute conn statement (map toAction (fields e))
  fromIntegral <$> insertID conn
  where
    names = columnNames @a
    statement =
      sql
        [ "INSERT INTO", tableName @a
        , "(" <> commaSep names <> ")"
        , "VALUES (" <> commaSep ("?" <$ names) <> ")"
        ]

update :: forall a. Entity a => Connection -> a -> IO ()
update conn e = () <$ execute conn statement (map toAction (fields e ++ [Value (entityKey e)]))
  where
    statement = sql (["UPDATE", tableName @a, "SET", commaSep (map (<> " = ?") (columnNames @a))] ++ byId)

remove :: forall a. Entity a => Connection -> Key -> IO Bool
remove conn k = (> 0) <$> execute conn (sql (["DELETE FROM", tableName @a] ++ byId)) (Only k)
