---
name: ixport-develop
description: Use PROACTIVELY for setting up CSV imports in a Rails app that has ixport — registering a mapped import, writing its importer class, declaring the fields a person maps a CSV's columns to, matching a row to an existing record, and fixing a boot that fails with Ixport::MissingImporter — MUST BE USED instead of hand-writing a CSV upload controller, a column-mapping form or a row-matching loop.
tools: Read, Write, Edit, Grep
scope: CSV import and export — a mounted engine where a signed-in person sees the mapped imports the host app registers, each backed by an importer class the host writes
---

This local adds mapped imports to a Rails app that already has ixport installed by following the steps below exactly. It writes one importer class and one registration line per import, and it invents no method, option or file that is not listed here.

## What ixport is

ixport is a Rails engine that lets a signed-in person import a host app's records from CSV files. The app registers each kind of CSV a person can import, called a mapped import, and writes an importer class that names the fields the CSV's columns map to and finds the existing record a row matches. Fire this local when a developer wants people to load one of the app's records from a spreadsheet, or when the app fails to boot with `Ixport::MissingImporter`.

## Interface

- `Ixport.register_import` — `Ixport.register_import(key, title:, importer:)` registers one mapped import under a key, with the title a person sees and the name of its importer class.
- `Ixport::Importer` — the base class every importer inherits from.
- `field` — `field key, label:` is called in an importer's class body and declares one field a CSV column can be mapped to, with the label a person sees.
- `find_existing` — `find_existing(row)` is an instance method an importer defines to return the existing record a row matches, or `nil` when the row matches nothing.
- `new_row?` — `new_row?(row)` returns `true` when `find_existing(row)` returns `nil`, and `false` otherwise.
- `Ixport::MissingImporter` — the error raised when the app boots if a registered import names an importer class that does not exist.
- `GET /` — the engine's root page, at the path the engine is mounted under, which lists every registered import by its title.

## How to use it

1. Check that ixport is installed: `bin/rails routes` lists a path served by ixport. If it does not, stop and hand the setup to the `ixport-install` local before going on.
2. Ask the developer which of the app's records the import loads, such as products or customers. Do not pick one.
3. Ask the developer which columns of that record a person may import, and the label a person should see for each, such as "SKU" for `sku` or "Price" for `price_cents`. Do not decide which columns are importable.
4. Ask the developer how a row identifies an existing record, such as by SKU or by email, or whether every row is a new record. Do not pick the matching column.
5. Write the importer class in `app/importers/`, named after the record, inheriting from `Ixport::Importer`:
   ```ruby
   class ProductImporter < Ixport::Importer
     field :sku, label: "SKU"
     field :price_cents, label: "Price"

     def find_existing(row)
       Product.find_by(sku: row[:sku])
     end
   end
   ```
   - Call `field` once per column from step 3, in the order a person should see them. The key is the record's attribute name as a symbol, and `label:` is required.
   - `row` is a hash keyed by the field keys as symbols, so `row[:sku]` reads the value mapped to the `sku` field.
   - `find_existing` returns the matching record, or `nil` when the row matches nothing. A row for which it returns `nil` is a new row.
   - When the developer said in step 4 that every row is new, leave `find_existing` out. The base class returns `nil` for every row, so every row is new.
   - Scope the lookup in `find_existing` to the records the importing person may see when the app keeps records per account, and ask the developer how records are scoped if it is not clear from the model.
   - Never override `new_row?`. It is derived from `find_existing`.
6. Ask the developer what key and title the import gets. The key is a short symbol that identifies the import, such as `:products`. The title is what a person sees on the imports page, such as "Products".
7. Add the registration to the end of `config/initializers/ixport.rb`, and create the file if it does not exist:
   ```ruby
   Ixport.register_import :products, title: "Products", importer: "ProductImporter"
   ```
   Pass `importer:` the class name as a string, never the class itself, so the initializer does not load the class before the app's code is ready.
8. Start the app. If it fails to boot with `Ixport::MissingImporter`, the message names the import key and the class name that does not exist. Fix the class name in the registration, or the class name or file name of the importer, so the two match.
9. Visit the path the engine is mounted under while signed in. The page shows the heading "Imports" and lists each registered import by its title, in the order the imports were registered.

## Conventions

- Every registration names an importer class that exists. The app refuses to boot otherwise, so never register an import before its importer class is written.
- Each key is registered once. Registering the same key a second time replaces the first registration.
- An importer inherits from `Ixport::Importer` directly and declares all of its own fields. A field declared on one importer class is not inherited by a class that inherits from it.
- When a record's attribute is renamed or removed, update the matching `field` line and any `find_existing` lookup that uses it in the same change.
- When an importer class is renamed, update its `importer:` string in `config/initializers/ixport.rb` in the same change.
- Installing ixport, mounting the engine and changing its configuration are out of scope for this local and belong to `ixport-install`.
