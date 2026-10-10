module Newspaper.Report (printMaterialReport) where

import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Database.MySQL.Simple (Connection, query_)
import Database.MySQL.Simple.QueryResults (QueryResults (..))
import Newspaper.Console (say, tshow)
import Newspaper.Field (FieldValue (..))
import Newspaper.Model (Kind)
import Text.Printf (printf)

data MaterialReport = MaterialReport
  { reportTitle :: Text
  , reportKind :: Kind
  , reportAuthors :: Maybe Text
  , reportViews :: Int
  , reportDownloads :: Int
  , reportReviews :: Int
  , reportRating :: Maybe Double
  }

instance QueryResults MaterialReport where
  convertResults fs vs =
    let (t, k, a, v, d, r, avg) = convertResults fs vs
     in MaterialReport t k a v d r avg

materialReports :: Connection -> IO [MaterialReport]
materialReports conn =
  query_
    conn
    "SELECT m.title, m.kind, \
    \  (SELECT GROUP_CONCAT(a.full_name ORDER BY a.full_name SEPARATOR ', ') \
    \     FROM material_authors ma JOIN authors a ON a.id = ma.author_id \
    \    WHERE ma.material_id = m.id), \
    \  COALESCE(s.views, 0), COALESCE(s.downloads, 0), \
    \  (SELECT COUNT(*) FROM reviews r WHERE r.material_id = m.id), \
    \  (SELECT CAST(AVG(r.rating) AS DOUBLE) FROM reviews r WHERE r.material_id = m.id) \
    \FROM materials m LEFT JOIN material_stats s ON s.material_id = m.id \
    \ORDER BY COALESCE(s.views, 0) DESC"

formatReport :: MaterialReport -> Text
formatReport r =
  T.unlines
    [ reportTitle r <> " [" <> showValue (reportKind r) <> "]"
    , "  Автори: " <> fromMaybe "—" (reportAuthors r)
    , "  Перегляди: " <> tshow (reportViews r) <> ", завантаження: " <> tshow (reportDownloads r)
    , "  Відгуків: " <> tshow (reportReviews r) <> ", середня оцінка: " <> maybe "—" (T.pack . printf "%.2f") (reportRating r)
    ]

printMaterialReport :: Connection -> IO ()
printMaterialReport conn = materialReports conn >>= mapM_ (say . formatReport)
