module Integral.Functions
  ( Function (..)
  , catalog
  , defaultFunction
  , lookupFunction
  , exactValue
  ) where

import Data.List (find)

data Function = Function
  { name :: String
  , formula :: String
  , apply :: Double -> Double
  , antiderivative :: Maybe (Double -> Double)
  }

defaultFunction :: Function
defaultFunction = Function "xsin" "x * sin x" (\x -> x * sin x) (Just (\x -> sin x - x * cos x))

catalog :: [Function]
catalog =
  [ defaultFunction
  , Function "poly" "x^3 - 2x + 1" (\x -> x ^ (3 :: Int) - 2 * x + 1) (Just (\x -> x ^ (4 :: Int) / 4 - x * x + x))
  , Function "exp" "e^(-x) * cos x" (\x -> exp (-x) * cos x) (Just (\x -> exp (-x) * (sin x - cos x) / 2))
  , Function "sqrt" "sqrt(1 + x^2)" (\x -> sqrt (1 + x * x)) (Just (\x -> (x * sqrt (1 + x * x) + asinh x) / 2))
  , Function "gauss" "e^(-x^2)" (\x -> exp (-(x * x))) Nothing
  ]

lookupFunction :: String -> Maybe Function
lookupFunction n = find ((== n) . name) catalog

exactValue :: Function -> Double -> Double -> Maybe Double
exactValue fn a b = (\g -> g b - g a) <$> antiderivative fn
