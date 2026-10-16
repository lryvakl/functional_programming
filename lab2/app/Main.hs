module Main (main) where

import Control.Concurrent (getNumCapabilities)
import Control.DeepSeq (force)
import Control.Exception (evaluate)
import GHC.Clock (getMonotonicTime)
import Integral.Functions (Function (..), catalog, defaultFunction, exactValue, lookupFunction)
import Integral.Parallel (integrateParallel)
import Integral.Quadrature (Estimate (Estimate), Rule, Simpson (..), Trapezoid (..), integrate)
import Options.Applicative
import Text.Printf (printf)

data Method = MethodTrapezoid | MethodSimpson

data Options = Options Function Double Double Double Method (Maybe Int)

withRule :: Method -> (forall r. Rule r => r -> a) -> a
withRule MethodTrapezoid k = k Trapezoid
withRule MethodSimpson k = k Simpson

methodName :: Method -> String
methodName MethodTrapezoid = "trapezoid"
methodName MethodSimpson = "simpson"

options :: Parser Options
options =
  Options
    <$> option (maybeReader lookupFunction)
      (long "function" <> short 'f' <> metavar "NAME" <> value defaultFunction
        <> help ("Integrand: " <> unwords (map name catalog)))
    <*> option auto (short 'a' <> metavar "A" <> value 0 <> help "Lower bound")
    <*> option auto (short 'b' <> metavar "B" <> value 100 <> help "Upper bound")
    <*> option auto (long "eps" <> short 'e' <> metavar "EPS" <> value 1e-9 <> help "Accuracy")
    <*> option (maybeReader parseMethod)
      (long "method" <> short 'm' <> metavar "trapezoid|simpson" <> value MethodTrapezoid <> help "Quadrature rule")
    <*> optional (option auto (long "threads" <> short 't' <> metavar "N" <> help "Number of threads (default: RTS capabilities)"))
  where
    parseMethod = \case
      "trapezoid" -> Just MethodTrapezoid
      "simpson" -> Just MethodSimpson
      _ -> Nothing

timed :: IO a -> IO (a, Double)
timed run = do
  start <- getMonotonicTime
  result <- run
  end <- getMonotonicTime
  pure (result, end - start)

report :: String -> Maybe Double -> (Estimate, Double) -> IO ()
report label exact (Estimate v n ok, seconds) = do
  printf "%-12s J = %.12f  steps = %d  time = %.3fs" label v n seconds
  maybe (pure ()) (printf "  |error| = %.2e" . abs . subtract v) exact
  putStrLn (if ok then "" else "  (accuracy not reached)")

main :: IO ()
main = do
  Options fn a b eps method threads <- execParser (info (options <**> helper) (fullDesc <> progDesc "Parallel computation of J(A,B) = integral of f(x) dx from A to B"))
  k <- maybe getNumCapabilities pure threads
  let exact = exactValue fn a b
  printf "f(x) = %s, A = %g, B = %g, eps = %g, method = %s, threads = %d\n" (formula fn) a b eps (methodName method) k
  maybe (pure ()) (printf "exact        J = %.12f\n") exact
  sequential <- withRule method $ \rule -> timed (evaluate (force (integrate rule eps (apply fn) a b)))
  parallel <- withRule method $ \rule -> timed (integrateParallel rule k eps (apply fn) a b)
  report "sequential" exact sequential
  report "parallel" exact parallel
  printf "speedup      %.2fx\n" (snd sequential / snd parallel)
