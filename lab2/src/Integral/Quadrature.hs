module Integral.Quadrature
  ( Rule (..)
  , Trapezoid (..)
  , Simpson (..)
  , Estimate (..)
  , integrate
  ) where

import Control.DeepSeq (NFData)
import GHC.Generics (Generic)

class Rule r where
  order :: r -> Int
  approximate :: r -> (Double -> Double) -> Double -> Double -> Int -> Double

data Trapezoid = Trapezoid

data Simpson = Simpson

instance Rule Trapezoid where
  order _ = 2
  approximate _ f a b n = h * ((f a + f b) / 2 + nodes f a h 1 (n - 1) 1)
    where
      h = (b - a) / fromIntegral n

instance Rule Simpson where
  order _ = 4
  approximate _ f a b n = h / 3 * (f a + f b + 4 * nodes f a h 1 (n - 1) 2 + 2 * nodes f a h 2 (n - 2) 2)
    where
      h = (b - a) / fromIntegral n

nodes :: (Double -> Double) -> Double -> Double -> Int -> Int -> Int -> Double
nodes f a h from to step = go from 0
  where
    go !i !acc
      | i > to = acc
      | otherwise = go (i + step) (acc + f (a + fromIntegral i * h))

data Estimate = Estimate
  { value :: !Double
  , steps :: !Int
  , converged :: !Bool
  }
  deriving stock (Show, Generic)
  deriving anyclass (NFData)

instance Semigroup Estimate where
  Estimate v s c <> Estimate v' s' c' = Estimate (v + v') (s + s') (c && c')

instance Monoid Estimate where
  mempty = Estimate 0 0 True

initialSteps, maxSteps :: Int
initialSteps = 16
maxSteps = 2 ^ (28 :: Int)

integrate :: Rule r => r -> Double -> (Double -> Double) -> Double -> Double -> Estimate
integrate rule eps f a b = refine initialSteps (approximate rule f a b initialSteps)
  where
    rungeFactor = 2 ^ order rule - 1
    refine n coarse
      | abs (fine - coarse) / rungeFactor < eps = Estimate fine (2 * n) True
      | 2 * n >= maxSteps = Estimate fine (2 * n) False
      | otherwise = refine (2 * n) fine
      where
        fine = approximate rule f a b (2 * n)
