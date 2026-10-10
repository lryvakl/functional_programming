module Newspaper.App (run) where

import Control.Exception (bracket)
import Data.Proxy (Proxy (..))
import Database.MySQL.Simple (Connection, close, connect)
import Newspaper.Config (loadConnectInfo)
import Newspaper.Console (MenuItem, menu)
import Newspaper.Crud (crudMenu)
import Newspaper.Entity (Entity (..))
import Newspaper.Model
import Newspaper.Report (printMaterialReport)
import System.IO (hSetEncoding, stdin, stdout, utf8)

data Section = forall a. Entity a => Section (Proxy a)

sections :: [Section]
sections =
  [ Section (Proxy @Material)
  , Section (Proxy @Author)
  , Section (Proxy @MaterialAuthor)
  , Section (Proxy @PublicationFile)
  , Section (Proxy @Reader)
  , Section (Proxy @Review)
  , Section (Proxy @MaterialStats)
  ]

sectionItem :: Connection -> Section -> MenuItem
sectionItem conn (Section (_ :: Proxy a)) = (entityTitle @a, crudMenu @a conn)

run :: IO ()
run = do
  mapM_ (`hSetEncoding` utf8) [stdin, stdout]
  info <- loadConnectInfo
  bracket (connect info) close $ \conn ->
    menu "Мережева газета факультету" $
      map (sectionItem conn) sections ++ [("Зведений звіт по матеріалах", printMaterialReport conn)]
