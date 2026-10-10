---
name: ixport-install
description: Use to hook ixport into a project — adding the gem, checking Active Storage is set up, running the install generator and its migrations, mounting the engine, and configuring the sign-in check, the current person method, the current account method, the layout and the inline row limit.
tools: Bash, Read, Edit
scope: CSV import and export — a mounted engine where a signed-in person sees the mapped imports and the fixed exports the host app registers, each import backed by an importer class and each export by an exporter class the host writes
---

This local hooks ixport into a Rails app by following the steps below exactly. It invents no step, setting or file that is not listed here.

## What ixport is

ixport is a Rails engine with two pages of work for a signed-in person. On the imports page they upload a CSV file, match its columns to a host app's fields, preview which rows will add, update or be refused, and run the import to save those records into the host app. On the exports page they download a CSV file of the host app's records whose columns the host app has fixed in advance. Hook it in when a Rails app needs people to load data from spreadsheets or take its data out as spreadsheets.

## Interface

- `gem "ixport"` — the Gemfile line that adds ixport to the app. It also brings in Keystone UI, which draws ixport's pages.
- `bin/rails generate ixport:install` — copies two migrations into `db/migrate/`, one that creates the `ixport_imports` table and one that creates the `ixport_import_refusals` table. Exports keep nothing in the database and need no migration.
- `mount Ixport::Engine` — the line in `config/routes.rb` that serves ixport's pages under a path the app chooses. The imports page is at that path and the exports page is at that path followed by `/exports`.
- `Ixport.configure` — takes a block that receives the configuration object, where the app sets any of the five settings below.
- `config.authentication_method` — the name of the controller method run before every ixport page, imports and exports alike, as a symbol. It defaults to `:authenticate_user!`.
- `config.current_person_method` — the name of the controller method that returns the signed-in person running imports and exports, as a symbol. It defaults to `:current_user`.
- `config.current_account_method` — the name of the controller method that returns the account the person is working in, as a symbol. It defaults to `:current_account`.
- `config.layout` — the name of the host layout ixport's pages are drawn inside, as a string. It defaults to `"application"`.
- `config.inline_row_limit` — the most data rows an uploaded import file may have, not counting its header row, as an integer. A file with more is refused on the upload page with a message giving the limit and the file's row count. It does not limit exports. It defaults to `1_000`.

## How to use it

1. Check that the app has Keystone UI set up: the layout ixport will use has `<%= keystone_theme_attributes %>` in its `<html>` tag. If it does not, stop and hand Keystone UI's setup to the `keystone_ui-install` local before going on, because ixport's pages are drawn with Keystone UI components and its styles.
2. Check that the app has Active Storage set up, because ixport keeps each uploaded import file as an Active Storage attachment. All three must hold:
   - `config/application.rb` loads Active Storage, either through `require "rails/all"` or through `require "active_storage/engine"`.
   - `db/schema.rb` has the `active_storage_blobs`, `active_storage_attachments` and `active_storage_variant_records` tables.
   - Each environment file in `config/environments/` sets `config.active_storage.service`, and `config/storage.yml` defines that service.

   If any is missing, tell the developer ixport cannot accept uploads without Active Storage and ask before setting it up. Where the tables are missing, setting it up means running `bin/rails active_storage:install` and then `bin/rails db:migrate`. Ask the developer which storage service each environment should use rather than picking one.
3. Add the gem to the app's `Gemfile`:
   ```ruby
   gem "ixport"
   ```
   Then run `bundle install`.
4. Run the install generator:
   ```bash
   bin/rails generate ixport:install
   ```
   It writes two files and touches no other:
   - `db/migrate/<timestamp>_create_ixport_imports.rb` creates the `ixport_imports` table with a required `key` string, a required polymorphic `person` reference, an optional polymorphic `account` reference, a `mapping` JSON column, a required `status` string defaulting to `"pending"`, required `added_count` and `updated_count` integers defaulting to `0`, and timestamps.
   - `db/migrate/<timestamp>_create_ixport_import_refusals.rb` creates the `ixport_import_refusals` table with a required `import` reference with a foreign key to `ixport_imports`, a required `row_number` integer, a required `reason` text, and timestamps.
5. Run the migrations:
   ```bash
   bin/rails db:migrate
   ```
6. Ask the developer which path ixport's pages should live under. There is no default path. Add the mount inside `Rails.application.routes.draw` in `config/routes.rb`, using their answer:
   ```ruby
   mount Ixport::Engine => "/data_imports"
   ```
   If the app's routes put signed-in pages inside a block such as `authenticate :user do`, ask the developer whether the mount goes inside it.
7. Read the app's `ApplicationController` and the controller methods it gets from its sign-in setup. ixport's controllers inherit from the app's `ApplicationController`, so every method named in the next step must be callable from it.
8. Compare the app's method and layout names with the defaults in the Interface section. Every default matches a Jumpstart app, so an app that uses all of the defaults needs no configuration. Where any name differs, or a method does not exist, ask the developer which method or layout to use rather than picking one:
   - The sign-in check: the method that sends a person who is not signed in to sign in, such as `:authenticate_user!` or `:require_login`.
   - The current person: the method returning the signed-in person, such as `:current_user` or `:current_member`. An import belongs to this person, and another person who opens it gets a not found response. Each export is built for this person when it is downloaded.
   - The current account: the method returning the team or company the person works inside, such as `:current_account` or `:current_team`. An import belongs to this account too, and the same person who opens it from another account gets a not found response. Each export is built for this account when it is downloaded. Ask whether the app has accounts at all. ixport calls the named method on every import page and every export download, so an app with no accounts still needs a method of that name callable from `ApplicationController`, and it returns `nil`. Ask the developer before adding one.
   - The layout: the file in `app/views/layouts/` that ixport's pages should be drawn inside.
   - The inline row limit: ask only if the developer wants a limit other than 1,000 rows per import file.
9. Write only the settings that differ from the defaults into a new initializer, `config/initializers/ixport.rb`:
   ```ruby
   Ixport.configure do |config|
     config.authentication_method = :require_login
     config.current_person_method = :current_member
     config.current_account_method = :current_team
     config.layout = "back_office"
     config.inline_row_limit = 5_000
   end
   ```
   The values above are examples, and each line is written only when the developer's answer differs from the default.
10. Start the app and visit the mounted path while signed in. The page shows the heading "Imports" and the message "No imports are set up yet." Then visit the mounted path followed by `/exports`. The page shows the heading "Exports" and the message "No exports are set up yet." Visiting either while signed out sends the browser through the app's own sign-in check.

## Conventions

- After installing, check that `bin/rails db:migrate:status` lists both the create-ixport-imports and the create-ixport-import-refusals migrations as up, that `bin/rails routes` lists the mount path, and that both pages load as described in step 10.
- Run the install generator once. A second run against unchanged copies reports each migration as identical and adds nothing. If a copied migration differs from the one the generator would write, the run stops with an error naming that migration, and copies nothing after it. Do not delete or edit a copied migration once it has been run.
- When the app renames its sign-in method, its current person or account method, or the layout ixport uses, update the matching line in `config/initializers/ixport.rb` in the same change.
- A setting given the same value as its default is left out of the initializer. Remove a line when its value goes back to the default.
- If the app fails to boot after installing, with an error saying an ixport import or export names a class that does not exist, the app registered an import or export whose class is missing. Fixing it is out of scope for this local and belongs to `ixport-develop`.
- Setting up the imports and exports that appear on the two pages, and the upload, mapping, preview, run, result and download pages they lead to, is out of scope for this local and belongs to `ixport-develop`.
