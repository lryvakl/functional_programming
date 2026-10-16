# Lab 2 — Parallel Definite Integral

## Task

Using Haskell (GHC with `-threaded`), build a multithreaded program that computes
the definite integral

```
J(A, B) = ∫ f(x) dx   from A to B
```

with a given accuracy **ε** using parallel algorithms.

## Requirements

- GHC ≥ 9.6, cabal-install ≥ 3.10

macOS:

```bash
brew install ghc cabal-install
```

## Run

```bash
cabal run integral -- [options]
```

| Option | Meaning | Default |
|---|---|---|
| `-f, --function NAME` | integrand: `xsin`, `poly`, `exp`, `sqrt`, `gauss` | `xsin` |
| `-a A` | lower bound | `0` |
| `-b B` | upper bound | `100` |
| `-e, --eps EPS` | required accuracy | `1e-9` |
| `-m, --method` | `trapezoid` or `simpson` | `trapezoid` |
| `-t, --threads N` | number of threads | number of CPU cores |

Available integrands:

| Name | f(x) | Exact value known |
|---|---|---|
| `xsin` | x · sin x | yes |
| `poly` | x³ − 2x + 1 | yes |
| `exp` | e^(−x) · cos x | yes |
| `sqrt` | √(1 + x²) | yes |
| `gauss` | e^(−x²) | no |

Examples:

```bash
cabal run integral -- -f xsin -a 0 -b 100 -e 1e-9 -m trapezoid -t 4
cabal run integral -- -f gauss -a 0 -b 5 -e 1e-12 -m simpson
cabal run integral -- --help
```

## Example output

```
f(x) = x * sin x, A = 0.0, B = 100.0, eps = 1.0e-9, method = trapezoid, threads = 4
exact        J = -86.738252869878
sequential   J = -86.738252869623  steps = 16777216  time = 0.261s  |error| = 2.55e-10
parallel     J = -86.738252869279  steps = 12582912  time = 0.066s  |error| = 5.99e-10
speedup      3.97x
```

The program computes the integral sequentially and in parallel, then prints both results,
the actual error (when the exact value is known), time, and speedup.

Measured speedup on the default example:

| Threads | Time | Speedup |
|---|---|---|
| 1 | 0.262 s | 1.0× |
| 2 | 0.131 s | 2.0× |
| 4 | 0.066 s | ~3.9× |
| 8 | 0.052 s | 4.8× |

For cheap tasks (e.g. Simpson's rule needing only a few thousand steps) parallel overhead
outweighs the work, so there is no speedup.

## Algorithm

1. Split `[A, B]` into `k` equal segments, where `k` is the number of threads.
2. Each segment is integrated in its own thread (`forkFinally` + `MVar`) with accuracy `ε / k`,
   so the total error stays within `ε`.
3. On each segment the step count doubles until the **Runge rule** is satisfied:
   `|I(2n) − I(n)| / (2^p − 1) < ε / k`, where `p` is the order of the method
   (2 for trapezoid, 4 for Simpson).
4. Segment results are combined via the `Monoid` instance of `Estimate`.
   An exception in any worker thread is re-thrown in the main thread.

The executable is built with `-threaded -rtsopts -with-rtsopts=-N`, so it uses all cores by default.
Override at runtime with e.g. `+RTS -N2`.

## Project structure

```
app/Main.hs                 CLI, sequential vs parallel comparison, timing
src/Integral/
  Quadrature.hs             Rule class (Trapezoid, Simpson), Estimate, Runge refinement
  Parallel.hs               parallelMap on threads, integrateParallel
  Functions.hs              integrand catalog with antiderivatives
```

## Design

- **`class Rule`** — a quadrature rule: its order and the approximation for `n` steps.
  Instances: `Trapezoid`, `Simpson`. A new rule only needs a new instance.
- **`Estimate`** — value, step count, and convergence flag; a `Semigroup`/`Monoid`, so partial
  results combine with `mconcat`.
- `parallelMap` is a generic helper: it runs any pure function on a list in separate threads,
  fully evaluating results (`NFData`) inside the worker thread.
