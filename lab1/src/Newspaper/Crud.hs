{-# LANGUAGE AllowAmbiguousTypes #-}

module Newspaper.Crud (crudMenu) where

import Control.Monad (zipWithM)
import Data.Bool (bool)
import Data.Text (Text)
import Database.MySQL.Simple (Connection)
import Newspaper.Console (ask, askKey, askOr, menu, say, tshow)
import Newspaper.Entity (Column (..), Entity (..), Key, describe)
import Newspaper.Field (display, runRowParser)
import Newspaper.Repository (findAll, findById, insert, remove, update)

crudMenu :: forall a. Entity a => Connection -> IO ()
crudMenu conn =
  menu
    (entityTitle @a)
    [ ("Переглянути всі", listAll)
    , ("Додати", create)
    , ("Редагувати", edit)
    , ("Видалити", delete)
    ]
  where
    labels = map columnLabel (columns @a)

    listAll =
      findAll @a conn >>= \case
        [] -> say "Записів немає"
        rows -> mapM_ (say . describe) rows

    create = do
      inputs <- mapM ask labels
      withParsed 0 inputs $ \e -> insert conn e >>= say . ("Додано запис #" <>) . tshow

    edit = withExisting $ \e -> do
      inputs <- zipWithM askOr labels (map display (fields e))
      withParsed (entityKey e) inputs $ \e' -> update conn e' >> say "Запис оновлено"

    delete = withKey $ \k -> remove @a conn k >>= say . bool "Запис не знайдено" "Запис видалено"

    withKey action = askKey >>= maybe (say "Некоректний ID") action

    withExisting action = withKey $ \k -> findById @a conn k >>= maybe (say "Запис не знайдено") action

    withParsed :: Key -> [Text] -> (a -> IO ()) -> IO ()
    withParsed k inputs action = either (say . ("Помилка введення: " <>)) action (runRowParser (parser @a k) inputs)
