# Functional Programming Labs (Haskell)

| Lab | Topic | Folder |
|---|---|---|
| 1 | Faculty online newspaper — information system on MySQL using type classes | [`lab1`](lab1/README.md) |
| 2 | Parallel computation of a definite integral with accuracy ε (`-threaded`) | [`lab2`](lab2/README.md) |
| 3 | Programming textbook text processing with custom text types | [`lab3`](lab3/README.md) |

## Common requirements

- GHC ≥ 9.6 and cabal-install ≥ 3.10
- macOS (Homebrew): `brew install ghc cabal-install`

Each lab is a standalone cabal project. Build and run from inside its folder:

```bash
cd labN
cabal build
cabal run <executable> -- <args>
```

See each lab's README for details.
