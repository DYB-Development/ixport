---
name: ixport-develop
description: Use PROACTIVELY for setting up CSV imports and exports in a Rails app that has ixport — registering a mapped import, writing its importer class, declaring the fields a person maps a CSV's columns to, choosing the field rows are matched on, scoping the records an import may add or update to the signed-in person or account, linking to an import's upload page, explaining the upload, column-matching, preview and result pages and their messages, explaining what running an import saves and refuses, registering a fixed export, writing its exporter class, declaring its columns including columns taken from a related record, computing a column's value, scoping the records an export may hold, linking to the exports page or one export's CSV download, and fixing a boot that fails with Ixport::MissingImporter or Ixport::MissingExporter — MUST BE USED instead of hand-writing a CSV upload controller, a column-mapping form, a row-matching loop, an import preview, a loop that saves imported rows, a CSV download action or a loop that writes records to a CSV.
tools: Bash, Read, Write, Edit, Grep
scope: CSV import and export — a mounted engine where a signed-in person sees the mapped imports and the fixed exports the host app registers, each import backed by an importer class and each export by an exporter class the host writes
---

This local adds mapped imports and fixed exports to a Rails app that already has ixport installed by following the steps below exactly. It writes one importer or exporter class and one registration line per import or export, and it invents no method, option, route or file that is not listed here.

## What ixport is

ixport is a Rails engine that lets a signed-in person import a host app's records from CSV files and download them as CSV files. The app registers each kind of CSV a person can import, called a mapped import, and writes an importer class that names the fields the CSV's columns map to, the one field rows are matched on, and the records a row may add to or update. A person picks an import, uploads a CSV file for it, matches each of the file's columns to one of the importer's fields, sees a preview of how many rows will add a record, update one or be refused, runs the import to save those rows, and then sees how many rows were added and updated and each refused row. The app also registers each CSV a person can download, called a fixed export, and writes an exporter class that names the columns the file holds, in order, and the records it holds one row each for. A person picks an export from the exports page and downloads its CSV. Fire this local when a developer wants people to load one of the app's records from a spreadsheet or download them as one, wants to link to an import's upload page, the exports page or an export's download, asks what the upload, column-matching, preview, result or exports pages do, asks what running an import saves or what an export's file holds, or when the app fails to boot with `Ixport::MissingImporter` or `Ixport::MissingExporter`.

## Interface

- `Ixport.register_import` — `Ixport.register_import(key, title:, importer:)` registers one mapped import under a key, with the title a person sees and the name of its importer class.
- `Ixport::Importer` — the base class every importer inherits from.
- `field` — `field key, label:` is called in an importer's class body and declares one field a CSV column can be mapped to, with the label a person sees.
- `match_on` — `match_on key` is called in an importer's class body and names the one declared field a row is matched to an existing record on.
- `records` — an instance method every importer and every exporter defines: in an importer it returns the Active Record relation a row may update a record from and adds a new record to, and in an exporter it returns the records the CSV holds, one row each, in the order returned.
- `person` — returns the signed-in person, for use inside `records` and `value`: in an importer the person who uploaded the file, in an exporter the person downloading it.
- `account` — returns the current account, for use inside `records` and `value`: in an importer the account current when the file was uploaded, in an exporter the account current when the file is downloaded, and `nil` when the app has no current account.
- `Ixport::MissingImporter` — the error raised when the app boots if a registered import names an importer class that does not exist.
- `Ixport::MissingExporter` — the error raised when the app boots if a registered export names an exporter class that does not exist.
- `GET /` — the engine's root page, at the path the engine is mounted under, which lists every registered import by its title, each linking to that import's upload page.
- `GET /imports/new` — the upload page for one import, given the import's registered key as the `key` query parameter, which shows the import's title, a CSV file field and an Upload button.
- `POST /imports` — takes the `key` and `file` parameters, stores the uploaded file as an import belonging to the signed-in person and the current account, and redirects to that import's column-matching page.
- `GET /imports/:import_id/mapping` — the column-matching page, titled "Match columns", which lists each column header from the file's first row beside a select of the importer's field labels and a "Skip" choice.
- `PATCH /imports/:import_id/mapping` — saves which field each column maps to and redirects to the import's preview page.
- `GET /imports/:import_id/preview` — the preview page, titled "Preview", which shows how many rows will add a record, update one or be refused, lists each updating row and each refused row by its row number, saves nothing, and offers a "Run import" button, and which redirects to the import's result page once the import has run.
- `POST /imports/:import_id/run` — saves every row that adds or updates a record, records every refused row with its reason, marks the import finished, and redirects to the import's result page, and does nothing but redirect when the import has already run.
- `GET /imports/:id` — the result page, titled "Import finished", which shows how many rows the run added and updated and lists each refused row by its row number with its reason, and which redirects to the import's preview page when the import has not run.
- `Ixport.register_export` — `Ixport.register_export(key, title:, exporter:)` registers one fixed export under a key, with the title a person sees and the name of its exporter class.
- `Ixport::Exporter` — the base class every exporter inherits from.
- `column` — `column key, label:, through: nil` is called in an exporter's class body and declares one column of the CSV, with the header a person sees, read from the record's `key` attribute, or from the `key` attribute of the related record named by `through:`.
- `value` — `value(record, column)` is the instance method that returns one cell of the CSV for one record and one declared column, and an exporter may override it to compute a cell.
- `GET /exports` — the exports page, titled "Exports", which lists every registered export by its title, each linking to its download.
- `GET /exports/:id` — downloads the CSV of the export registered under the key given as `:id`, as a file named after that key.

## How to use it

Steps 1 to 19 add a mapped import. Steps 20 to 31 add a fixed export. Do step 1 first in either case.

1. Check that ixport is installed: `bin/rails routes` lists a path served by ixport. If it does not, stop and hand the setup to the `ixport-install` local before going on.

### A mapped import

2. Ask the developer which of the app's records the import loads, such as products or customers. Do not pick one.
3. Ask the developer which attributes of that record a person may import, and the label a person should see for each, such as "SKU" for `sku` or "Price" for `price_cents`. Do not decide which attributes are importable.
4. Ask the developer which of those fields identifies an existing record, such as the SKU or the email. Do not pick the match field.
5. Ask the developer which records a person may add to or update, such as the current account's products or the signed-in person's contacts. Do not pick the scope. An import that reaches every row of the table lets one account's file update another account's records.
6. Write the importer class in `app/importers/`, named after the record, inheriting from `Ixport::Importer`:
   ```ruby
   class ProductImporter < Ixport::Importer
     field :sku, label: "SKU"
     field :price_cents, label: "Price"
     match_on :sku

     def records
       account.products
     end
   end
   ```
   - Call `field` once per attribute from step 3, in the order a person should see them. The key is the record's attribute name as a symbol, and `label:` is required.
   - Each field key must be an attribute the record can be assigned, because a row's mapped values are assigned to the record by those keys.
   - The labels are the choices on the column-matching page, in the order the fields are declared.
   - Call `match_on` once, with the key of a field declared with `field`, from step 4.
   - Define `records` to return a relation of the record from step 5, built from `person` or `account`. A new record is built from this relation, so a record added through `account.products` already belongs to that account.
   - `account` is `nil` when the app has no current account, so a `records` that calls a method on `account` fails in that case. Ask the developer whether that can happen in this app.
   - Never define `initialize` in an importer. ixport builds the importer with the import's person and account.
7. Ask the developer what key and title the import gets. The key is a short symbol that identifies the import, such as `:products`. The title is what a person sees on the imports page and as the heading of the upload page, such as "Products".
8. Add the registration to the end of `config/initializers/ixport.rb`, and create the file if it does not exist:
   ```ruby
   Ixport.register_import :products, title: "Products", importer: "ProductImporter"
   ```
   Pass `importer:` the class name as a string, never the class itself, so the initializer does not load the class before the app's code is ready.
9. Start the app. If it fails to boot with `Ixport::MissingImporter`, the message names the import key and the class name that does not exist. Fix the class name in the registration, or the class name or file name of the importer, so the two match.
10. Visit the path the engine is mounted under while signed in. The page shows the heading "Imports" and lists each registered import by its title, in the order the imports were registered. With no import registered it shows "No imports are set up yet."
11. When the developer wants a link to one import's upload page from the app's own pages, ask where the link goes. Build its URL with the engine's route helper and the import's registered key:
    ```erb
    <%= link_to "Import products", ixport.new_import_path(key: :products) %>
    ```
    The key must be one that is registered. An unregistered key gets a not found response.
12. On the upload page a person chooses a CSV file and presses Upload. The upload is refused, and the upload page is shown again with status 422 and one of these messages, when:
    - the file has no header row: "This file has no header row."
    - the file has more data rows than the inline row limit, not counting the header row: "This file has N rows, and the most an import can have is L." The limit is set by `ixport-install`.
13. After an upload is accepted, the person is on the "Match columns" page. Each column header from the file's first row is listed with a select of the importer's field labels. "Skip" leaves that column unmapped. Pressing "Save mapping" saves the choices and takes the person to the "Preview" page.
14. The preview decides each data row's outcome this way:
    - The row's value for the match field is looked up in `records`, with one query for the whole file.
    - A row matches a record only when its value is exactly the same text as the record's match attribute written as text.
    - A row that matches a record will update it with the row's mapped values.
    - A row that matches nothing, a row whose match value is blank, and every row of a file with no column mapped to the match field will add a new record built from `records`.
    - A row whose added or updated record is not valid will be refused, with the record's own validation messages as the reason.
15. The preview page shows three counts, "Will add", "Will update" and "Will be refused". Under them it lists each row that will update a record under "Will update", and each refused row with its reason under "Will be refused", each by its row number in the file, where the header row is row 1. The refusal reasons are the record's validation messages, so tell the developer that the record's validations decide which rows are refused and what a person reads.
16. Viewing the preview adds and changes no record. Its back link returns the person to the "Match columns" page to change the mapping.
17. Pressing "Run import" on the preview page runs the import within the same request, with no background job:
    - Every row's outcome is decided again by the rules in step 14, against the records as they are at that moment, so the result can differ from the preview when records changed in between.
    - Every row that adds or updates a record is saved with `save!`, so the record's callbacks run as for any other save.
    - Every refused row is recorded with its row number and reason, and no record is saved for it.
    - The whole run happens in one database transaction. When any save raises, such as on a database constraint the record's validations do not cover, nothing from the run is saved and the import stays unrun. Tell the developer to cover every database constraint on the record with a validation, so a bad row is refused rather than stopping the whole run.
    - An import runs once. A second run request for the same import, including one sent at the same time as the first, adds and changes nothing and redirects to the result page.
18. After the run, the person is on the "Import finished" page. It shows two counts, "Added" and "Updated", and, when any row was refused, lists each refused row under "Refused" by its row number with its reason. Returning to this page later shows the same counts and refused rows. Visiting this page for an import that has not run redirects to its preview page. Once an import has run, its preview page redirects to this page, so it offers no "Run import" button.
19. An import's column-matching, preview, run and result pages are visible only to the person who uploaded it, in the account it was uploaded in. Anyone else, and the same person in another account, gets a not found response.

### A fixed export

20. Ask the developer which of the app's records the export holds, such as products or customers. Do not pick one.
21. Ask the developer which columns the file holds, in order, and the header a person should see for each, such as "SKU" for `sku`. For each column, ask whether it is an attribute of the record itself, an attribute of a related record such as the product's account name, or a value computed from the record. Do not decide which columns are exported.
22. Ask the developer which records the file holds, such as the current account's products, and in what order its rows go. Do not pick the scope or the order. An export that reaches every row of the table lets one account download another account's records.
23. Write the exporter class in `app/exporters/`, named after the record, inheriting from `Ixport::Exporter`:
    ```ruby
    class ProductExporter < Ixport::Exporter
      column :sku, label: "SKU"
      column :price_cents, label: "Price"
      column :name, label: "Account", through: :account

      def records
        account.products.includes(:account).order(:sku)
      end
    end
    ```
    - Call `column` once per column from step 21, in the order the columns appear in the file. `label:` is required and is that column's header in the file's first row.
    - For an attribute of the record itself, the key is the attribute's name as a symbol.
    - For an attribute of a related record, pass `through:` the name of the association on the record, and the key is the attribute's name on the related record. A record whose related record is `nil` gets an empty cell in that column.
    - Define `records` to return the records from step 22, built from `person` or `account`, in the row order from step 22. The file has one row per record, in the order `records` returns them.
    - When any column uses `through:`, add `includes` for each association it names to `records`, so the download does not run one query per row.
    - `account` is `nil` when the app has no current account, so a `records` that calls a method on `account` fails in that case. Ask the developer whether that can happen in this app.
    - Never define `initialize` in an exporter. ixport builds the exporter with the signed-in person and the current account.
24. For a computed column from step 21, declare it with `column` under a key of your choosing and override `value` to return it, calling `super` for every other column:
    ```ruby
    def value(record, column)
      return record.price_cents / 100.0 if column.key == :price

      super
    end
    ```
    - `column.key` is the column's key as a symbol, and `column.label` is its header.
    - Ask the developer how the computed value is written, such as how many decimal places, rather than picking a format.
25. Every cell is written as the value's `to_s`, and a `nil` value is an empty cell. When the developer needs a date, time or amount written a particular way, compute that column in `value` as in step 24.
26. Ask the developer what key and title the export gets. The key is a short symbol that identifies the export, such as `:products`, and is also the downloaded file's name, such as `products.csv`. The title is what a person sees on the exports page, such as "Products".
27. Add the registration to the end of `config/initializers/ixport.rb`, and create the file if it does not exist:
    ```ruby
    Ixport.register_export :products, title: "Products", exporter: "ProductExporter"
    ```
    Pass `exporter:` the class name as a string, never the class itself, so the initializer does not load the class before the app's code is ready.
28. Start the app. If it fails to boot with `Ixport::MissingExporter`, the message names the export key and the class name that does not exist. Fix the class name in the registration, or the class name or file name of the exporter, so the two match.
29. Visit `exports` under the path the engine is mounted under while signed in. The page shows the heading "Exports" and lists each registered export by its title, in the order the exports were registered, each linking to its download. With no export registered it shows "No exports are set up yet." The engine's root page lists imports only and does not link to this page.
30. When the developer wants a link to the exports page or to one export's download from the app's own pages, ask where the link goes. Build its URL with the engine's route helpers and the export's registered key:
    ```erb
    <%= link_to "Exports", ixport.exports_path %>
    <%= link_to "Download products", ixport.export_path(:products) %>
    ```
    The key must be one that is registered. An unregistered key gets a not found response.
31. A download builds the whole file within the same request, with no background job and no row limit, from the records `records` returns for the person downloading it, in the account current at that moment. Tell the developer that an export over a very large table makes that request slow.

## Conventions

- Every registration names an importer or exporter class that exists. The app refuses to boot otherwise, so never register an import or export before its class is written.
- Each import key is registered once, and each export key is registered once. Registering the same key a second time replaces the first registration.
- Every importer declares `match_on` and defines `records`.
- Every exporter declares at least one `column` and defines `records`.
- `records` is always scoped to the `person` or `account` the developer chose, never left to the whole table without the developer saying so.
- An importer inherits from `Ixport::Importer` directly and declares all of its own fields and its own match field. An exporter inherits from `Ixport::Exporter` directly and declares all of its own columns. None of these is inherited by a class that inherits from another importer or exporter.
- An exporter that overrides `value` calls `super` for every column it does not compute.
- When a record's attribute or association is renamed or removed, update the matching `field`, `match_on` and `column` lines in the same change.
- When an importer or exporter class is renamed, update its `importer:` or `exporter:` string in `config/initializers/ixport.rb` in the same change.
- When an import's or export's key is changed, update every link to its upload page or download in the same change.
- Never write an upload form, a column-matching form, a preview page, a run action, a result page, an exports page, a CSV download action or a controller for them in the app. The engine serves all of them.
- Installing ixport, mounting the engine, the tables an import and its refused rows are stored in, file storage, sign-in, how the current person and account are found, the layout, and the inline row limit are out of scope for this local and belong to `ixport-install`.
