---
name: ixport-info
description: Use to learn what ixport offers — CSV import and export through a mounted Rails engine, the mapped imports a host app registers, the importer classes behind them, uploading a file and matching its columns, and the vocabulary the install and develop locals assume.
tools: Read
scope: CSV import and export — a mounted engine where a signed-in person sees the mapped imports the host app registers, each backed by an importer class the host writes
---

This local explains what ixport is and routes you to the local that does the work. It makes no changes and gives no steps.

## What ixport is

ixport is a Rails engine for moving a host app's records in and out of CSV files. The host app mounts it at a path of its choosing, and a signed-in person who visits that path sees the list of imports the host has set up, each shown by its title.

A person picks an import, uploads a CSV file, and then matches each column of the file to one of the columns the import reads, or skips it. ixport refuses a file with no header row, and a file with more rows than the host's row limit, on the upload page.

The engine owns the screens, the access check and its own table of import records, with the uploaded file stored through Active Storage. The host owns what each import means: which columns it reads and how a row is matched to a record the app already has. Reach for ixport when a Rails app needs people to load data from spreadsheets, rather than writing a one-off upload page per record type.

The engine renders its pages with Keystone UI inside a layout the host chooses, and it runs its access check through a method the host already has.

## Interface

ixport declares nothing for this local to document. Its surface is split between the other two locals:

- **ixport-install** owns hooking ixport into a host app: adding the gem, running its install generator, mounting the engine, and the configuration that names the host's sign-in check, current person, current account, layout and row limit.
- **ixport-develop** owns building against ixport: registering a mapped import, writing the importer class behind it, the error raised when a registration names an importer that does not exist, and the engine's pages for listing imports, uploading a file and matching its columns.

## How to use it

- The app does not have ixport yet, or you are changing how ixport reaches the app's sign-in, people, accounts, layout or row limit: use **ixport-install**.
- ixport is already installed and you are adding or changing an import, linking to the engine's pages, or the app fails to boot naming a missing importer: use **ixport-develop**.

## Conventions

- **Mapped import** — one kind of import the host registers, made of a key, a title shown to people, and the name of its importer class.
- **Key** — the short name a mapped import is registered and looked up by, held as a symbol.
- **Title** — the words a person sees for the import on the engine's page.
- **Importer** — a class the host app writes that declares the columns the import reads, each with a key and a label, and says how a row is matched to an existing record.
- **Import record** — one upload by one person, stored by the engine with the key of its mapped import, the uploaded file, and the mapping once it is saved.
- **Headers** — the first row of the uploaded file, read as the names of its columns.
- **Mapping** — which of the importer's columns each header in the file fills, stored by the header's position in the row. A header left on "Skip" is not stored.
- **Row limit** — the most data rows an uploaded file may have, not counting the header row. It defaults to 1,000 and the host can change it.
- **New row** — a CSV row the importer matched to no existing record in the host app.
- **Person** — whoever is signed in and running the import. ixport reaches them through a method the host names, so the host's user model needs no particular name.
- **Account** — the optional owner the person is working inside, such as a team or company, reached the same way. An app with no accounts runs without one.
- **Ownership** — an import record belongs to the person and account that uploaded it, and anyone else who opens it, including the same person from another account, is answered not found.
- **Boot check** — when the app starts, ixport checks that every registered importer class exists and refuses to boot when one does not, so a misspelled class name fails at startup rather than when someone runs the import.
- An import is registered by the host app, never discovered: an importer class that is not registered does not appear on the page.
