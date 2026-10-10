---
name: ixport-develop
description: Use PROACTIVELY for setting up CSV imports and exports in a Rails app that has ixport — registering a mapped import, writing its importer class, declaring the fields a person maps a CSV's columns to, choosing the field rows are matched on, scoping the records an import may add or update to the signed-in person or account, linking to an import's upload page, explaining the upload, column-matching, preview and result pages and their messages, explaining the list of a person's past imports on the imports page, explaining what running an import saves and refuses, explaining what a person sees when an import fails partway and which rows it keeps, running imports in a background job through the app's own runner class, explaining what a person sees while an import runs in the background, registering a fixed export or a chosen export, writing its exporter class, declaring its columns including columns taken from a related record, computing a column's value, scoping the records an export may hold, letting an account save named templates of picked columns for an export, explaining the new, edit and delete template pages and what a template's download holds, linking to the exports page, one export's CSV download or one template's download, making the app's own import job fail with Ixport::ImportFailed, and fixing a boot that fails with Ixport::MissingImporter or Ixport::MissingExporter — MUST BE USED instead of hand-writing a CSV upload controller, a column-mapping form, a row-matching loop, an import preview, a loop that saves imported rows, a background job that saves imported rows, a rescue that records why an import stopped, a CSV download action, a loop that writes records to a CSV, or a model and form for saved column picks.
tools: Bash, Read, Write, Edit, Grep
scope: CSV import and export — a mounted engine where a signed-in person sees the mapped imports and the exports the host app registers, each import backed by an importer class and each export by an exporter class the host writes, where an export is either fixed or chosen, and a chosen export lets the account save named templates of picked columns
---

This local adds mapped imports, fixed exports and chosen exports to a Rails app that already has ixport installed by following the steps below exactly. It writes one importer or exporter class and one registration line per import or export, and it invents no method, option, route or file that is not listed here.

## What ixport is

ixport is a Rails engine that lets a signed-in person import a host app's records from CSV files and download them as CSV files. The app registers each kind of CSV a person can import, called a mapped import, and writes an importer class that names the fields the CSV's columns map to, the one field rows are matched on, and the records a row may add to or update. A person picks an import, uploads a CSV file for it, matches each of the file's columns to one of the importer's fields, sees a preview of how many rows will add a record, update one or be refused, runs the import to save those rows, and then sees how many rows were added and updated and each refused row. When the run stops on an error, the import is marked failed, keeps the rows it saved before stopping, and its page shows the error. An import runs within the request by default, or, when the app is set up for it, in the background through wallflower or through a runner class the app writes. The imports page also lists the person's own past imports in the current account, each opening at the step it has reached. The app also registers each CSV a person can download, and writes an exporter class that names the columns the file can hold, in order, and the records it holds one row each for. An export is either fixed or chosen. A fixed export always holds every declared column, and a person downloads it from the exports page. A chosen export lets people in the current account save named templates, each a picked list of the exporter's columns in a picked order, and a person downloads a template from the exports page to get a file holding only those columns. Fire this local when a developer wants people to load one of the app's records from a spreadsheet or download them as one, wants people to pick which columns an export holds, wants to link to an import's upload page, the exports page, an export's download or a template's download, asks what the upload, column-matching, preview, result, exports or template pages do, asks what the list of past imports shows, asks what running an import saves, what happens when a run fails, or what an export's or template's file holds, wants imports run in a background job of the app's own, or when the app fails to boot with `Ixport::MissingImporter` or `Ixport::MissingExporter`.

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
- `Ixport::ImportFailed` — the error a background run is failed with when its import stopped on an error, carrying the import's error message: wallflower's task raises it, and the app's own job may raise it.
- `Ixport.run_import` — `Ixport.run_import(import)` or `Ixport.run_import(import, reporter: reporter)` runs one import that a runner was handed, as the signed-in person and in the account it was uploaded with, saving and refusing its rows the same way as a run within the request, marking the import failed rather than raising when the run stops on an error, and optionally reporting each row to `reporter`.
- `enqueue` — `enqueue(import)` is the class method the app's own runner class defines, which ixport calls with each import a person runs, once the import is marked running, so the runner can arrange for `Ixport.run_import` to run it later.
- `GET /` — the engine's root page, at the path the engine is mounted under, which lists every registered import by its title, each linking to that import's upload page, and then lists the signed-in person's past imports in the current account, newest first, each linking to the step it has reached.
- `GET /imports/new` — the upload page for one import, given the import's registered key as the `key` query parameter, which shows the import's title, a CSV file field and an Upload button.
- `POST /imports` — takes the `key` and `file` parameters, stores the uploaded file as an import belonging to the signed-in person and the current account, and redirects to that import's column-matching page.
- `GET /imports/:import_id/mapping` — the column-matching page, titled "Match columns", which lists each column header from the file's first row beside a select of the importer's field labels and a "Skip" choice.
- `PATCH /imports/:import_id/mapping` — saves which field each column maps to and redirects to the import's preview page.
- `GET /imports/:import_id/preview` — the preview page, titled "Preview", which shows how many rows will add a record, update one or be refused, lists each updating row and each refused row by its row number, saves nothing, and offers a "Run import" button, and which redirects to the import's result page once the import has finished or failed, or while it is running in the background.
- `POST /imports/:import_id/run` — with no background runner, saves every row that adds or updates a record, records every refused row with its reason, marks the import finished, or failed when the run stops on an error, and redirects to the import's result page, and does nothing but redirect when the import has already finished or failed; with a background runner, marks a pending import running, hands it to the runner, and redirects to the wallflower task's page or, for the app's own runner, to the import's result page, and hands nothing to the runner and redirects to the import's result page when the import is already running, finished or failed.
- `GET /imports/:id` — the result page, titled "Import finished", which shows how many rows the run added and updated and lists each refused row by its row number with its reason, titled "Import running" with the message "This import is running." while a background run is under way, titled "Import failed" with the error the run stopped on and the counts of rows saved before it stopped when the run failed, and which redirects to the import's preview page when the import has neither run nor started running.
- `Ixport.register_export` — `Ixport.register_export(key, title:, exporter:, chosen: false)` registers one export under a key, with the title a person sees and the name of its exporter class, as a fixed export by default or as a chosen export when `chosen: true`.
- `Ixport::Exporter` — the base class every exporter inherits from.
- `column` — `column key, label:, through: nil` is called in an exporter's class body and declares one column of the CSV, with the header a person sees, read from the record's `key` attribute, or from the `key` attribute of the related record named by `through:`.
- `value` — `value(record, column)` is the instance method that returns one cell of the CSV for one record and one declared column, and an exporter may override it to compute a cell.
- `GET /exports` — the exports page, titled "Exports", which lists every registered export by its title: a fixed export links to its download, and a chosen export lists the current account's templates for it with a "New template" button.
- `GET /exports/:id` — downloads the CSV of the export registered under the key given as `:id`, holding every declared column, as a file named after that key.
- `GET /exports/:export_id/templates/new` — the new template page for the chosen export registered under the key given as `:export_id`, which shows a "Template name" field and one column select per declared column.
- `POST /exports/:export_id/templates` — takes the `name` and `columns[]` parameters, saves a template for that chosen export belonging to the signed-in person and the current account, and redirects to the exports page.
- `GET /export_templates/:id` — downloads the CSV of one template, holding only its picked columns in its picked order, as a file named after the template's name.
- `GET /export_templates/:id/edit` — the edit template page, which shows the template's name and picked columns in the same fields as the new template page, and a Delete action.
- `PATCH /export_templates/:id` — takes the `name` and `columns[]` parameters, replaces the template's name and picked columns, and redirects to the exports page.
- `DELETE /export_templates/:id` — deletes the template and redirects to the exports page.

## How to use it

Steps 1 to 24 add a mapped import, and steps 19 to 23 of those cover running imports in the background. Steps 25 to 37 add an export, fixed or chosen. Steps 38 to 44 cover the templates of a chosen export. Do step 1 first in every case.

1. Check that ixport is installed: `bin/rails routes` lists a path served by ixport. If it does not, stop and hand the setup to the `ixport-install` local before going on. For any import, also check that `db/migrate/` has an `add_error_message_to_ixport_imports` migration and that it has run, because a run that stops on an error writes the column it adds, and without it the run raises an error naming the missing column. If it does not, hand the update to the `ixport-install` local before going on. To run imports in the background, also check that `db/migrate/` has an `add_wallflower_task_to_ixport_imports` migration and that it has run, because pressing "Run import" with any background runner reads the column it adds, including with the app's own runner. If it does not, hand the update to the `ixport-install` local before going on. For a chosen export, also check that `db/migrate/` has a `create_ixport_export_templates` migration and that it has run. If it does not, hand the update to the `ixport-install` local before going on.

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
10. Visit the path the engine is mounted under while signed in. The page shows the heading "Imports" and lists each registered import by its title, in the order the imports were registered. With no import registered it shows "No imports are set up yet." Below that, once the signed-in person has uploaded any file, a "Your imports" section lists their past imports:
    - It lists only imports uploaded by the signed-in person in the current account, newest first. Imports by other people, or by the same person in another account, are not listed.
    - Each shows the import's title, the uploaded file's name, its status, "Pending", "Running", "Finished" or "Failed", and the date it was uploaded, such as "Oct 10, 2026".
    - A finished import also shows its "Added", "Updated" and "Refused" counts. A pending, running or failed import shows no counts.
    - Each title links to the step the import has reached: the "Import finished" page once it has run, the "Preview" page once its mapping is saved with at least one column mapped, and otherwise the "Match columns" page. A running import's link leads to its "Import running" page, and a failed import's link leads to its "Import failed" page.
    - When the person has no past import, the section is not shown.
11. When the developer wants a link to one import's upload page from the app's own pages, ask where the link goes. Build its URL with the engine's route helper and the import's registered key:
    ```erb
    <%= link_to "Import products", ixport.new_import_path(key: :products) %>
    ```
    The key must be one that is registered. An unregistered key gets a not found response.
12. On the upload page a person chooses a CSV file and presses Upload. The upload is refused, and the upload page is shown again with status 422 and one of these messages, when:
    - the file is not UTF-8 text: "This file is not UTF-8 text. Save it as UTF-8 and upload it again."
    - the file is not valid CSV, such as a quote left open: "This file could not be read past line N. Check the quotes on that line."
    - the file has no header row: "This file has no header row."
    - the file has more data rows than the inline row limit, not counting the header row: "This file has N rows, and the most an import can have is L." The limit is set by `ixport-install`, and it applies only when imports run within the request. With a background runner, a file of any length is accepted.
13. After an upload is accepted, the person is on the "Match columns" page. Each column header from the file's first row is listed with a select of the importer's field labels. "Skip" leaves that column unmapped. Pressing "Save mapping" saves the choices and takes the person to the "Preview" page.
14. The preview decides each data row's outcome this way:
    - The row's value for the match field is looked up in `records`, with one query for the whole file.
    - A row matches a record only when its value is exactly the same text as the record's match attribute written as text.
    - A row that matches a record will update it with the row's mapped values.
    - A row that matches nothing, a row whose match value is blank, and every row of a file with no column mapped to the match field will add a new record built from `records`.
    - A row whose added or updated record is not valid will be refused, with the record's own validation messages as the reason.
15. The preview page shows three counts, "Will add", "Will update" and "Will be refused". Under them it lists each row that will update a record under "Will update", and each refused row with its reason under "Will be refused", each by its row number in the file, where the header row is row 1. The refusal reasons are the record's validation messages, so tell the developer that the record's validations decide which rows are refused and what a person reads.
16. Viewing the preview adds and changes no record. Its back link returns the person to the "Match columns" page to change the mapping.
17. When the app has no background runner, pressing "Run import" on the preview page runs the import within the same request, with no background job. Steps 19 to 23 cover an app with a background runner, where rows are saved and refused by the same rules. The run:
    - Every row's outcome is decided again by the rules in step 14, against the records as they are at that moment, so the result can differ from the preview when records changed in between.
    - Every row that adds or updates a record is saved with `save!`, so the record's callbacks run as for any other save.
    - Every refused row is recorded with its row number and reason, and no record is saved for it.
    - Rows are saved in file order, and each row's save is undone on its own when it raises.
    - When anything raises during the run, such as a save hitting a database constraint the record's validations do not cover, the run stops at that row. The rows saved and refused before it stay saved, the rows after it are neither saved nor refused, and the import is marked failed with the error's message and the counts of rows added and updated before it stopped.
    - The error is reported through Rails' error reporter, so it reaches whatever error service the app has subscribed there. It is not raised to the person's request.
    - Tell the developer to cover every database constraint on the record with a validation, so a bad row is refused rather than stopping the run.
    - An import runs once. A second run request for the same import, including one sent at the same time as the first, adds and changes nothing and redirects to the result page. A failed import is not run again, so the rows after the one it stopped on can only be loaded by uploading them as a new import.
18. After the run, the person is on the result page:
    - When the run finished, the page is titled "Import finished". It shows two counts, "Added" and "Updated", and, when any row was refused, lists each refused row under "Refused" by its row number with its reason.
    - When the run failed, the page is titled "Import failed". It shows the error's message, the line "Rows saved before it stopped stay saved.", the "Added" and "Updated" counts of rows saved before it stopped, and each row refused before it stopped.
    - The error's message is the exception's own message, such as a database's constraint error, so tell the developer that a person reads it as written.
    - Returning to this page later shows the same page. Visiting it for an import that has neither run nor started running redirects to its preview page. Once an import has finished or failed, its preview page redirects to this page, so it offers no "Run import" button.

### Running imports in the background

Whether imports run within the request, through wallflower, or through the app's own runner class is set by `ixport-install`. Steps 19 to 23 apply only when one of the two background runners is set.

19. With a background runner, pressing "Run import" marks the import running and hands it to the runner, and saves no row within the request:
    - With wallflower, the person is taken to the wallflower task's page, which shows the run's progress, the rows it changed and refused, and a link to the import's result page once the run ends. When the run failed, the task fails with `Ixport::ImportFailed` carrying the import's error message, and still links to the import's "Import failed" page.
    - With the app's own runner, the person is taken to the import's result page, titled "Import running", with the message "This import is running." and no counts. Once the run ends, the same page is titled "Import finished" or "Import failed" and shows what step 18 describes.
    - While the import runs, its preview page redirects to its "Import running" page, so it offers no "Run import" button, and the imports page lists it as "Running" with a link that leads to that page.
    - An import is handed to the runner once. A second run request for an import that is already running, finished or failed, such as one sent from a preview page left open, hands nothing to the runner and redirects to the import's result page.
20. For the app's own runner, ask the developer which background job system the app uses and which queue an import's job goes on. Do not pick either.
21. Write the runner class under the class name `ixport-install` set, with a class method `enqueue` that takes the import and starts a job, and write the job so it calls `Ixport.run_import` with the import:
    ```ruby
    class ImportRunner
      def self.enqueue(import)
        RunImportJob.perform_later(import)
      end
    end
    ```
    ```ruby
    class RunImportJob < ApplicationJob
      def perform(import)
        Ixport.run_import(import)
      end
    end
    ```
    - Pass the import itself to the job, as above, never its id, because the job gets the import back only from what it was passed.
    - `enqueue` is called within the person's request, so it must start the job and return, never run the import itself.
    - The value `enqueue` returns is not used.
22. `Ixport.run_import` runs the import by the rules in steps 14 and 17:
    - It builds the importer with the person who uploaded the file and the account current at that upload, so the job needs no signed-in person and `records` is scoped as it was for the preview.
    - It adds and changes nothing when the import has already finished or failed.
    - When the run stops on an error, it keeps the rows saved before it, marks the import failed, reports the error through Rails' error reporter, and returns without raising, as in step 17. The job therefore succeeds, and a retry of it would change nothing.
    - Ask the developer whether a failed import should also fail the job, such as to show it in the job system's failed list. If it should, raise `Ixport::ImportFailed` with the import's error message after the run, and turn off retries for it, since a retry changes nothing:
      ```ruby
      def perform(import)
        Ixport.run_import(import)
        raise Ixport::ImportFailed, import.error_message if import.failed?
      end
      ```
    - When `enqueue` raises, or the job never runs, the import stays running and its page keeps showing "This import is running.". Tell the developer this, and ask how they want such imports noticed.
23. When the developer wants to show a run's progress somewhere of their own, pass `reporter:` an object that answers all three of these, and ask the developer where the progress is shown:
    - `set_total(total)` is called once, before the first row, with the number of data rows.
    - `refuse(label:, reason:)` is called for each refused row, with a label such as "Row 4" and the refusal reason.
    - `advance` is called once after each row, saved or refused.
24. An import's column-matching, preview, run and result pages are visible only to the person who uploaded it, in the account it was uploaded in. Anyone else, and the same person in another account, gets a not found response.

### An export

25. Ask the developer which of the app's records the export holds, such as products or customers. Do not pick one.
26. Ask the developer which columns the file can hold, in order, and the header a person should see for each, such as "SKU" for `sku`. For each column, ask whether it is an attribute of the record itself, an attribute of a related record such as the product's account name, or a value computed from the record. Do not decide which columns are exported.
27. Ask the developer which records the file holds, such as the current account's products, and in what order its rows go. Do not pick the scope or the order. An export that reaches every row of the table lets one account download another account's records.
28. Ask the developer whether the export is fixed or chosen. Do not pick one.
    - Fixed: every download holds every column from step 26, in the declared order.
    - Chosen: people in the current account save named templates that each pick some of those columns in an order of their own, and each template downloads only its picked columns.
29. Write the exporter class in `app/exporters/`, named after the record, inheriting from `Ixport::Exporter`. A fixed export and a chosen export use the same kind of class:
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
    - Call `column` once per column from step 26, in the order the columns appear in the file. `label:` is required and is that column's header in the file's first row.
    - For a chosen export, the labels are the choices in each column select on the template pages, in the declared order.
    - Each column's key must be unique within the exporter, because a template records its picked columns by key.
    - For an attribute of the record itself, the key is the attribute's name as a symbol.
    - For an attribute of a related record, pass `through:` the name of the association on the record, and the key is the attribute's name on the related record. A record whose related record is `nil` gets an empty cell in that column.
    - Define `records` to return the records from step 27, built from `person` or `account`, in the row order from step 27. The file has one row per record, in the order `records` returns them.
    - When any column uses `through:`, add `includes` for each association it names to `records`, so the download does not run one query per row.
    - `account` is `nil` when the app has no current account, so a `records` that calls a method on `account` fails in that case. Ask the developer whether that can happen in this app.
    - Never define `initialize` in an exporter. ixport builds the exporter with the signed-in person and the current account.
30. For a computed column from step 26, declare it with `column` under a key of your choosing and override `value` to return it, calling `super` for every other column:
    ```ruby
    def value(record, column)
      return record.price_cents / 100.0 if column.key == :price

      super
    end
    ```
    - `column.key` is the column's key as a symbol, and `column.label` is its header.
    - Ask the developer how the computed value is written, such as how many decimal places, rather than picking a format.
    - A template's download writes its cells through the same `value`, so a computed column is computed the same way in every template that picks it.
31. Every cell is written as the value's `to_s`, and a `nil` value is an empty cell. When the developer needs a date, time or amount written a particular way, compute that column in `value` as in step 30.
32. Ask the developer what key and title the export gets. The key is a short symbol that identifies the export, such as `:products`, and is also the fixed export's downloaded file name, such as `products.csv`. The title is what a person sees on the exports page, such as "Products".
33. Add the registration to the end of `config/initializers/ixport.rb`, and create the file if it does not exist. For a fixed export:
    ```ruby
    Ixport.register_export :products, title: "Products", exporter: "ProductExporter"
    ```
    For a chosen export, add `chosen: true`:
    ```ruby
    Ixport.register_export :products, title: "Products", exporter: "ProductExporter", chosen: true
    ```
    Pass `exporter:` the class name as a string, never the class itself, so the initializer does not load the class before the app's code is ready.
34. Start the app. If it fails to boot with `Ixport::MissingExporter`, the message names the export key and the class name that does not exist. Fix the class name in the registration, or the class name or file name of the exporter, so the two match.
35. Visit `exports` under the path the engine is mounted under while signed in. The page shows the heading "Exports" and lists each registered export by its title, in the order the exports were registered. With no export registered it shows "No exports are set up yet." The engine's root page lists imports only and does not link to this page.
    - A fixed export's title links to its download.
    - A chosen export's title is not a link. Under it are the current account's templates for that export, ordered by name, each name linking to the template's download beside an "Edit" link, and then a "New template" button.
36. When the developer wants a link to the exports page or to one fixed export's download from the app's own pages, ask where the link goes. Build its URL with the engine's route helpers and the export's registered key:
    ```erb
    <%= link_to "Exports", ixport.exports_path %>
    <%= link_to "Download products", ixport.export_path(:products) %>
    ```
    The key must be one that is registered. An unregistered key gets a not found response. `export_path` also downloads a chosen export with every declared column, although the exports page does not link to it.
37. A download builds the whole file within the same request, with no background job and no row limit, from the records `records` returns for the person downloading it, in the account current at that moment. This holds for a template's download too. Tell the developer that an export over a very large table makes that request slow.

### The templates of a chosen export

38. Pressing "New template" on the exports page opens the page titled "New <export title> template", with a back link to the exports page. It shows a required "Template name" field and one select per declared column, labelled "Column 1", "Column 2" and so on. Each select offers every column's label and "None". Pressing "Save template" saves the template and returns the person to the exports page.
39. The picked columns are saved in this way:
    - They are kept in the order of the selects, so "Column 1" is the file's first column.
    - A select left at "None" adds nothing.
    - A column picked in more than one select is kept once, at its first position.
    - A template with no picked column produces a file with an empty header row and one empty row per record.
40. A template belongs to the current account. Every person in that account sees it on the exports page and can download, edit or delete it. A person in another account gets a not found response. When the app has no current account, every template saved with no account is shared by every signed-in person with no account. Tell the developer this, and ask whether it is what they want.
41. A template's name link downloads a CSV holding only its picked columns, in its picked order, with each column's label as the header and one row per record from `records`. The file is named after the template's name, lower-cased with spaces and punctuation replaced by hyphens, such as `price-list.csv` for "Price list".
42. Pressing "Edit" opens the page titled "Edit <template name>", with the export's title under it and a back link to the exports page. It shows the same fields as the new template page, filled with the template's name and picked columns. Pressing "Save template" replaces the name and picked columns by the rules in step 39 and returns the person to the exports page.
43. The edit page's action menu has a Delete item. It deletes the template and returns the person to the exports page.
44. When the developer wants a link to one template's download or edit page from the app's own pages, ask where the link goes, and build it with the engine's route helpers and the template:
    ```erb
    <%= link_to template.name, ixport.export_template_path(template) %>
    <%= link_to "Edit", ixport.edit_export_template_path(template) %>
    <%= link_to "New template", ixport.new_export_template_path(:products) %>
    ```
    `new_export_template_path` takes the chosen export's registered key. An unregistered key, or the key of a fixed export, gets a not found response.

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
- Past imports record their import's key. Before changing an import's key or removing its registration, tell the developer that while any past import under the old key remains, the engine's root page raises an error for the person who uploaded it, and ask what should happen to those imports.
- Saved templates record a chosen export's key and its picked column keys. Before changing a chosen export's key, removing its registration, or changing it to fixed, ask the developer what happens to the templates already saved for it:
  - A template whose export key is no longer registered no longer shows on the exports page, and opening its download or edit page raises an error.
  - A template whose export is changed to fixed no longer shows on the exports page, and its download and edit links still work.
- When a chosen export's column key is renamed or removed, saved templates that picked it drop that column from their downloads without saying so. Tell the developer before making that change.
- Never write an upload form, a column-matching form, a preview page, a run action, a result page, an exports page, a CSV download action, a template form or model, or a controller for them in the app. The engine serves all of them.
- The app's own runner only starts a job, and the job only calls `Ixport.run_import`. Never write a job that reads the file, matches rows or saves records itself.
- When the app's own runner class is renamed, tell the developer that the class name `ixport-install` set must be changed in the same change.
- Never wrap `Ixport.run_import` in a rescue, a transaction or a retry of the app's own. It records its own failure, keeps the rows saved before it, and reports the error.
- Installing ixport, running the update generator for the export templates table, the background runner's column or the failed import's error column, subscribing an error service to Rails' error reporter, mounting the engine, the tables an import, its refused rows and export templates are stored in, file storage, sign-in, how the current person and account are found, the layout, the inline row limit, and choosing whether imports run within the request, through wallflower or through the app's own runner class are out of scope for this local and belong to `ixport-install`.
