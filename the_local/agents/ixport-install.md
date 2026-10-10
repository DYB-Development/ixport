---
name: ixport-install
description: Use to hook ixport into a project — adding the gem, running the install generator and its migration, mounting the engine, and configuring the sign-in check, the current person method, the current account method, the layout and the inline row limit.
tools: Bash, Read, Edit
scope: CSV import and export — a mounted engine where a signed-in person sees the mapped imports the host app registers, each backed by an importer class the host writes
---

This local hooks ixport into a Rails app by following the steps below exactly. It invents no step, setting or file that is not listed here.

## What ixport is

ixport is a Rails engine that lets a signed-in person import a host app's records from CSV files. Hook it in when a Rails app needs people to load data from spreadsheets.

## Interface

- `gem "ixport"` — the Gemfile line that adds ixport to the app. It also brings in Keystone UI, which draws ixport's pages.
- `bin/rails generate ixport:install` — copies one migration into `db/migrate/` that creates the `ixport_imports` table.
- `mount Ixport::Engine` — the line in `config/routes.rb` that serves ixport's pages under a path the app chooses.
- `Ixport.configure` — takes a block that receives the configuration object, where the app sets any of the five settings below.
- `config.authentication_method` — the name of the controller method run before every ixport page, as a symbol. It defaults to `:authenticate_user!`.
- `config.current_person_method` — the name of the controller method that returns the signed-in person running imports, as a symbol. It defaults to `:current_user`.
- `config.current_account_method` — the name of the controller method that returns the account the person is working in, as a symbol. It defaults to `:current_account`.
- `config.layout` — the name of the host layout ixport's pages are drawn inside, as a string. It defaults to `"application"`.
- `config.inline_row_limit` — the most rows an import may have and still run inside the web request, as an integer. It defaults to `1_000`.

## How to use it

1. Check that the app has Keystone UI set up: the layout ixport will use has `<%= keystone_theme_attributes %>` in its `<html>` tag. If it does not, stop and hand Keystone UI's setup to the `keystone_ui-install` local before going on, because ixport's pages are drawn with Keystone UI components and its styles.
2. Add the gem to the app's `Gemfile`:
   ```ruby
   gem "ixport"
   ```
   Then run `bundle install`.
3. Run the install generator:
   ```bash
   bin/rails generate ixport:install
   ```
   It writes `db/migrate/<timestamp>_create_ixport_imports.rb`, which creates the `ixport_imports` table with a `key` string, a required polymorphic `person` reference, an optional polymorphic `account` reference, and timestamps. It touches no other file.
4. Run the migration:
   ```bash
   bin/rails db:migrate
   ```
5. Ask the developer which path ixport's pages should live under. There is no default path. Add the mount inside `Rails.application.routes.draw` in `config/routes.rb`, using their answer:
   ```ruby
   mount Ixport::Engine => "/data_imports"
   ```
   If the app's routes put signed-in pages inside a block such as `authenticate :user do`, ask the developer whether the mount goes inside it.
6. Read the app's `ApplicationController` and the controller methods it gets from its sign-in setup. ixport's controllers inherit from the app's `ApplicationController`, so every method named in the next step must be callable from it.
7. Compare the app's method and layout names with the defaults in the Interface section. Every default matches a Jumpstart app, so an app that uses all of the defaults needs no configuration. Where any name differs, or a method does not exist, ask the developer which method or layout to use rather than picking one:
   - The sign-in check: the method that sends a person who is not signed in to sign in, such as `:authenticate_user!` or `:require_login`.
   - The current person: the method returning the signed-in person, such as `:current_user` or `:current_member`.
   - The current account: the method returning the team or company the person works inside, such as `:current_account` or `:current_team`. Ask whether the app has accounts at all, since the import table allows an import with no account.
   - The layout: the file in `app/views/layouts/` that ixport's pages should be drawn inside.
   - The inline row limit: ask only if the developer wants a limit other than 1,000 rows.
8. Write only the settings that differ from the defaults into a new initializer, `config/initializers/ixport.rb`:
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
9. Start the app and visit the mounted path while signed in. The page shows the heading "Imports" and the message "No imports are set up yet." Visiting it while signed out sends the browser through the app's own sign-in check.

## Conventions

- After installing, check that `bin/rails db:migrate:status` lists the create-ixport-imports migration as up, that `bin/rails routes` lists the mount path, and that the page at that path loads as described in step 9.
- Run the install generator once. A second run stops with an error naming the migration the app already has, and adds nothing. Do not delete or edit the copied migration once it has been run.
- When the app renames its sign-in method, its current person or account method, or the layout ixport uses, update the matching line in `config/initializers/ixport.rb` in the same change.
- A setting given the same value as its default is left out of the initializer. Remove a line when its value goes back to the default.
- Setting up the imports that appear on the page is out of scope for this local and belongs to `ixport-develop`.
