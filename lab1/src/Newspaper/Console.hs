module Newspaper.Console
  ( MenuItem
  , say
  , tshow
  , ask
  , askOr
  , askKey
  , menu
  ) where

import Control.Exception (Handler (..), SomeException, catches, displayException, throwIO)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import System.Exit (ExitCode, exitSuccess)
import System.IO (hFlush, isEOF, stdout)
import Text.Read (readMaybe)

type MenuItem = (Text, IO ())

say :: Text -> IO ()
say = T.putStrLn

tshow :: Show a => a -> Text
tshow = T.pack . show

ask :: Text -> IO Text
ask label = do
  T.putStr (label <> ": ")
  hFlush stdout
  eof <- isEOF
  if eof then exitSuccess else T.strip <$> T.getLine

askOr :: Text -> Text -> IO Text
askOr label current = orCurrent <$> ask (label <> " [" <> current <> "]")
  where
    orCurrent t = if T.null t then current else t

askKey :: IO (Maybe Int)
askKey = readMaybe . T.unpack <$> ask "ID запису"

menu :: Text -> [MenuItem] -> IO ()
menu title items = loop
  where
    numbered = zip (map tshow [1 :: Int ..]) items
    loop = do
      say ("\n=== " <> title <> " ===")
      mapM_ (\(n, (label, _)) -> say (n <> ". " <> label)) numbered
      say "0. Назад"
      choice <- ask "Оберіть пункт"
      case (choice, lookup choice numbered) of
        ("0", _) -> pure ()
        (_, Just (_, action)) -> safely action >> loop
        _ -> say "Невідомий пункт" >> loop

safely :: IO () -> IO ()
safely action =
  action
    `catches` [ Handler (\(e :: ExitCode) -> throwIO e)
              , Handler (\(e :: SomeException) -> say ("Помилка: " <> T.pack (displayException e)))
              ]
