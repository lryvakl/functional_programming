# Lab 3 — Programming Textbook Text Processing

## Task

Write a Haskell program that processes the text of a programming textbook (read from a file)
using types such as **Symbol**, **Word**, **Sentence**, **Punctuation**, etc.
Whenever text is produced, tabs and runs of spaces are replaced with a single space.

**Variant 1:** sort all words of the text by ascending number of occurrences of a given letter.
Words with the same count are sorted alphabetically.

## Requirements

- GHC ≥ 9.6, cabal-install ≥ 3.10

macOS:

```bash
brew install ghc cabal-install
```

## Run

```bash
cabal run textbook -- FILE -l LETTER [--unique] [--show-text]
```

| Option | Meaning |
|---|---|
| `FILE` | path to the textbook text file (UTF-8) |
| `-l, --letter CHAR` | letter to count (required, must be a single letter) |
| `-u, --unique` | remove duplicate words |
| `-s, --show-text` | also print the normalized text, one sentence per line |

Examples (a sample text is in `data/textbook.txt`):

```bash
cabal run textbook -- data/textbook.txt -l а
cabal run textbook -- data/textbook.txt -l а --unique --show-text
```

## Example output

Each line is `<count of the letter>  <word>`:

```
  0  3.14
  0  Double
  0  Haskell
  ...
  1  дані
  1  значення
  1  Кожна
  ...
  2  Програма
  2  програмування
  2  функціональна
```

With `--show-text` the normalized text is printed first:

```
Haskell — це чисто функціональна мова програмування.
Програма на Haskell складається з функцій, які обчислюють значення!
```

## Rules

**Words**
- A word is a sequence of letters, digits, and `_`.
- `-`, `'`, and `.` between two word characters stay inside the word,
  so `будь-яке`, `п'ять`, `3.14`, and `obj.method` are single words.

**Sentences**
- A sentence ends with `.`, `!`, `?`, or `…`.
- All whitespace (tabs, spaces, newlines) collapses into a single space.

**Sorting**
1. By the number of occurrences of the given letter, ascending.
2. Ties: alphabetically, case-insensitive, using the Ukrainian alphabet order
   (`а б в г ґ д е є ж з и і ї й … ю я`). Latin letters and digits come before Cyrillic.
3. Letter counting is also case-insensitive.

A custom collation is used because plain Unicode order puts `і`, `є`, `ї`, `ґ` after `я`.

## Project structure

```
app/Main.hs                 CLI
src/Textbook/
  Types.hs                  Symbol, Word, Punctuation, Token, Sentence, Text; HasWords class
  Render.hs                 Render class — turns structures back into text
  Parser.hs                 tokenizer and sentence splitter
  Analysis.hs               letter counting, sorting, Ukrainian collation
data/textbook.txt           sample input
```

## Design

| Type | Meaning |
|---|---|
| `Symbol` | a single character |
| `Word` | a list of `Symbol`s |
| `Punctuation` | a punctuation mark |
| `Token` | a word, punctuation mark, other symbol, or a single space |
| `Sentence` | a list of `Token`s |
| `Text` | a list of `Sentence`s |

- **`class Render`** — rendering for every text type; whitespace is already normalized during parsing.
- **`class HasWords`** — extracts words from a token, a sentence, or the whole text.
