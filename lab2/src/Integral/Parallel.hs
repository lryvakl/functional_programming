module Integral.Parallel
  ( parallelMap
  , integrateParallel
  , segments
  ) where

import Control.Concurrent (forkFinally)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Control.DeepSeq (NFData, force)
import Control.Exception (evaluate, throwIO)
import Integral.Quadrature (Estimate, Rule, integrate)

parallelMap :: NFData b => (a -> b) -> [a] -> IO [b]
parallelMap f xs = mapM spawn xs >>= mapM (\v -> takeMVar v >>= either throwIO pure)
  where
    spawn x = do
      result <- newEmptyMVar
      _ <- forkFinally (evaluate (force (f x))) (putMVar result)
      pure result

segments :: Int -> Double -> Double -> [(Double, Double)]
segments k a b = zip points (drop 1 points)
  where
    h = (b - a) / fromIntegral k
    points = [a + h * fromIntegral i | i <- [0 .. k - 1]] ++ [b]

integrateParallel :: Rule r => r -> Int -> Double -> (Double -> Double) -> Double -> Double -> IO Estimate
integrateParallel rule k eps f a b =
  mconcat <$> parallelMap (uncurry (integrate rule (eps / fromIntegral k) f)) (segments k a b)
