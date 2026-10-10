# Lab 1 — Faculty Online Newspaper

## Task

Build a Haskell program that uses **classes and instances**, with **MySQL** as the database.

Information system "Faculty online newspaper". The database stores:

- article or graphic material title, authors, annotation text
- where publication files are stored
- readers and their reviews
- statistics for individual materials

The program must support entering and editing data. The database must have more than 5 tables.

## Requirements

- GHC ≥ 9.6, cabal-install ≥ 3.10
- MySQL server ≥ 8.0
- C libraries: `pcre`, `pkg-config` (needed by the `mysql` / `mysql-simple` Haskell packages)

macOS:

```bash
brew install ghc cabal-install mysql pcre pkg-config
```

## Setup

### 1. Start MySQL

```bash
brew services start mysql
```

If the service does not come up (`mysqladmin -uroot ping` fails), start the server directly:

```bash
/opt/homebrew/opt/mysql/bin/mysqld --datadir=/opt/homebrew/var/mysql &
```

### 2. Create the database and load sample data

```bash
mysql -uroot < sql/schema.sql
mysql -uroot < sql/seed.sql
```

`schema.sql` drops and recreates all tables, so re-running it resets the database.

### 3. Point cabal at the C libraries

Create `cabal.project.local` (machine-specific, git-ignored). Homebrew on Apple Silicon:

```
package pcre-light
    extra-include-dirs: /opt/homebrew/opt/pcre/include
    extra-lib-dirs: /opt/homebrew/opt/pcre/lib

package mysql
    extra-include-dirs: /opt/homebrew/opt/mysql/include/mysql
    extra-lib-dirs: /opt/homebrew/opt/mysql/lib /opt/homebrew/opt/openssl@3/lib /opt/homebrew/opt/zstd/lib
```

`cabal.project` pins `Cabal < 3.14` because the custom `Setup.hs` of `pcre-light` does not compile with newer Cabal.

## Run

```bash
cabal run newspaper
```

Connection settings come from environment variables:

| Variable | Default |
|---|---|
| `DB_HOST` | `127.0.0.1` |
| `DB_PORT` | `3306` |
| `DB_USER` | `root` |
| `DB_PASSWORD` | *(empty)* |
| `DB_NAME` | `faculty_newspaper` |

Example: `DB_PASSWORD=secret cabal run newspaper`

Stop MySQL when done:

```bash
mysqladmin -uroot shutdown
```

## Usage

The program is an interactive console menu (UI text is in Ukrainian):

```
=== Мережева газета факультету ===
1. Матеріали (статті та графіка)     materials
2. Автори                            authors
3. Авторство матеріалів              material ↔ author links
4. Файли публікацій                  publication files
5. Читачі                            readers
6. Відгуки                           reviews
7. Статистика матеріалів             material statistics
8. Зведений звіт по матеріалах       summary report
0. Назад                             back / exit
```

Every table section has the same submenu: **list all**, **add**, **edit**, **delete**.
When editing, the current value is shown in brackets — press Enter to keep it.

Input is validated: material type must be `article` or `graphic`, rating must be 1–5,
dates use `YYYY-MM-DD`. Database errors (e.g. a foreign key to a missing record) are shown without crashing.

Summary report example:

```
Хакатон факультету 2026 [article]
  Автори: Андрій Мельник, Олена Коваль
  Перегляди: 340, завантаження: 25
  Відгуків: 2, середня оцінка: 4.50
```

## Database schema (7 tables)

| Table | Contents |
|---|---|
| `authors` | full name, position, email |
| `materials` | title, kind (`article` / `graphic`), annotation, publication date |
| `material_authors` | many-to-many link between materials and authors |
| `publication_files` | file path and format for each material |
| `readers` | full name, email, student group |
| `reviews` | reader's rating (1–5) and comment on a material |
| `material_stats` | views and downloads per material |

Foreign keys use `ON DELETE CASCADE`.

## Project structure

```
app/Main.hs                 entry point
src/Newspaper/
  Field.hs                  FieldValue class, Value, RowParser
  Entity.hs                 Entity class
  Model.hs                  entity types and their instances
  Repository.hs             generic CRUD SQL for any Entity
  Crud.hs                   generic CRUD console menu for any Entity
  Report.hs                 summary statistics report
  Console.hs                input/output helpers, menu loop
  Config.hs                 DB connection settings from env
  App.hs                    main menu wiring
sql/schema.sql              tables
sql/seed.sql                sample data
```

## Design

- **`class FieldValue`** — how a single field is parsed from user input, shown, and passed to SQL.
  Instances: `Text`, `Int`, `Day`, `Kind`, `Rating` (`Rating` only accepts 1–5).
- **`class Entity`** — table name, columns, field values, and a parser that builds the record from input.
  Each of the 7 tables has an instance.
- `Repository` and `Crud` are written once for any `Entity`. Adding a table means adding a type and its instance — no other code changes.
- Library classes `QueryResults`, `Param`, `Result` from `mysql-simple` are also instantiated for the model types.
