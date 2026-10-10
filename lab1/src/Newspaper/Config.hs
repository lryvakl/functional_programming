module Newspaper.Config (loadConnectInfo) where

import Data.Maybe (fromMaybe)
import Database.MySQL.Base.Types (Option (..))
import Database.MySQL.Simple (ConnectInfo (..), defaultConnectInfo)
import System.Environment (getEnvironment)
import Text.Read (readMaybe)

loadConnectInfo :: IO ConnectInfo
loadConnectInfo = do
  env <- getEnvironment
  let setting key def = fromMaybe def (lookup key env)
  pure
    defaultConnectInfo
      { connectHost = setting "DB_HOST" "127.0.0.1"
      , connectPort = fromMaybe 3306 (lookup "DB_PORT" env >>= readMaybe)
      , connectUser = setting "DB_USER" "root"
      , connectPassword = setting "DB_PASSWORD" ""
      , connectDatabase = setting "DB_NAME" "faculty_newspaper"
      , connectOptions = [CharsetName "utf8mb4"]
      }
