module Newspaper.Model
  ( Kind (..)
  , Rating
  , mkRating
  , Author (..)
  , Material (..)
  , MaterialAuthor (..)
  , PublicationFile (..)
  , Reader (..)
  , Review (..)
  , MaterialStats (..)
  ) where

import Control.Exception (throw)
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B8
import Data.Proxy (Proxy (..))
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (Day)
import Data.Typeable (Typeable, typeRep)
import Database.MySQL.Base.Types (Field (..))
import Database.MySQL.Simple.Param (Param (..))
import Database.MySQL.Simple.QueryResults (QueryResults (..))
import Database.MySQL.Simple.Result (Result (..), ResultError (..))
import Newspaper.Entity (Column (..), Entity (..), Key)
import Newspaper.Field (FieldValue (..), Value (..), field, parseEnum)

refine :: forall b a. (Result b, Typeable a) => (b -> Either Text a) -> Field -> Maybe ByteString -> a
refine p f v = either (throw . failure . T.unpack) id (p (convert f v))
  where
    failure = ConversionFailed (show (fieldType f)) (show (typeRep (Proxy @a))) (B8.unpack (fieldName f))

data Kind = Article | Graphic
  deriving (Eq, Show, Enum, Bounded)

instance FieldValue Kind where
  parseValue = parseEnum
  showValue = \case
    Article -> "article"
    Graphic -> "graphic"

instance Param Kind where
  render = render . showValue

instance Result Kind where
  convert = refine parseEnum

newtype Rating = Rating Int
  deriving (Eq, Show)

mkRating :: Int -> Either Text Rating
mkRating n
  | n >= 1 && n <= 5 = Right (Rating n)
  | otherwise = Left "оцінка має бути від 1 до 5"

instance FieldValue Rating where
  parseValue t = parseValue t >>= mkRating
  showValue (Rating n) = showValue n

instance Param Rating where
  render (Rating n) = render n

instance Result Rating where
  convert = refine mkRating

data Author = Author
  { authorId :: Key
  , authorName :: Text
  , authorPosition :: Text
  , authorEmail :: Text
  }

instance QueryResults Author where
  convertResults fs vs = let (k, n, p, e) = convertResults fs vs in Author k n p e

instance Entity Author where
  tableName = "authors"
  entityTitle = "Автори"
  columns = [Column "full_name" "ПІБ", Column "position" "Посада", Column "email" "Email"]
  entityKey = authorId
  fields (Author _ n p e) = [Value n, Value p, Value e]
  parser k = Author k <$> field <*> field <*> field

data Material = Material
  { materialId :: Key
  , materialTitle :: Text
  , materialKind :: Kind
  , materialAnnotation :: Text
  , materialPublishedOn :: Day
  }

instance QueryResults Material where
  convertResults fs vs = let (k, t, c, a, d) = convertResults fs vs in Material k t c a d

instance Entity Material where
  tableName = "materials"
  entityTitle = "Матеріали (статті та графіка)"
  columns =
    [ Column "title" "Назва"
    , Column "kind" "Тип (article/graphic)"
    , Column "annotation" "Анотація"
    , Column "published_on" "Дата публікації"
    ]
  entityKey = materialId
  fields (Material _ t c a d) = [Value t, Value c, Value a, Value d]
  parser k = Material k <$> field <*> field <*> field <*> field

data MaterialAuthor = MaterialAuthor
  { linkId :: Key
  , linkMaterial :: Key
  , linkAuthor :: Key
  }

instance QueryResults MaterialAuthor where
  convertResults fs vs = let (k, m, a) = convertResults fs vs in MaterialAuthor k m a

instance Entity MaterialAuthor where
  tableName = "material_authors"
  entityTitle = "Авторство матеріалів"
  columns = [Column "material_id" "ID матеріалу", Column "author_id" "ID автора"]
  entityKey = linkId
  fields (MaterialAuthor _ m a) = [Value m, Value a]
  parser k = MaterialAuthor k <$> field <*> field

data PublicationFile = PublicationFile
  { fileId :: Key
  , fileMaterial :: Key
  , filePath :: Text
  , fileFormat :: Text
  }

instance QueryResults PublicationFile where
  convertResults fs vs = let (k, m, p, f) = convertResults fs vs in PublicationFile k m p f

instance Entity PublicationFile where
  tableName = "publication_files"
  entityTitle = "Файли публікацій"
  columns = [Column "material_id" "ID матеріалу", Column "path" "Шлях", Column "format" "Формат"]
  entityKey = fileId
  fields (PublicationFile _ m p f) = [Value m, Value p, Value f]
  parser k = PublicationFile k <$> field <*> field <*> field

data Reader = Reader
  { readerId :: Key
  , readerName :: Text
  , readerEmail :: Text
  , readerGroup :: Text
  }

instance QueryResults Reader where
  convertResults fs vs = let (k, n, e, g) = convertResults fs vs in Reader k n e g

instance Entity Reader where
  tableName = "readers"
  entityTitle = "Читачі"
  columns = [Column "full_name" "ПІБ", Column "email" "Email", Column "grp" "Група"]
  entityKey = readerId
  fields (Reader _ n e g) = [Value n, Value e, Value g]
  parser k = Reader k <$> field <*> field <*> field

data Review = Review
  { reviewId :: Key
  , reviewMaterial :: Key
  , reviewReader :: Key
  , reviewRating :: Rating
  , reviewComment :: Text
  }

instance QueryResults Review where
  convertResults fs vs = let (k, m, r, s, c) = convertResults fs vs in Review k m r s c

instance Entity Review where
  tableName = "reviews"
  entityTitle = "Відгуки"
  columns =
    [ Column "material_id" "ID матеріалу"
    , Column "reader_id" "ID читача"
    , Column "rating" "Оцінка (1-5)"
    , Column "comment" "Коментар"
    ]
  entityKey = reviewId
  fields (Review _ m r s c) = [Value m, Value r, Value s, Value c]
  parser k = Review k <$> field <*> field <*> field <*> field

data MaterialStats = MaterialStats
  { statsId :: Key
  , statsMaterial :: Key
  , statsViews :: Int
  , statsDownloads :: Int
  }

instance QueryResults MaterialStats where
  convertResults fs vs = let (k, m, v, d) = convertResults fs vs in MaterialStats k m v d

instance Entity MaterialStats where
  tableName = "material_stats"
  entityTitle = "Статистика матеріалів"
  columns = [Column "material_id" "ID матеріалу", Column "views" "Перегляди", Column "downloads" "Завантаження"]
  entityKey = statsId
  fields (MaterialStats _ m v d) = [Value m, Value v, Value d]
  parser k = MaterialStats k <$> field <*> field <*> field
