---
name: ixport-install
description: Use to hook ixport into a project — adding the gem, checking Active Storage is set up, running the install generator and its migrations, running the update generator on an app that installed an earlier ixport, mounting the engine, and configuring the sign-in check, the current person method, the current account method, the layout, the inline row limit, the background runner and the base controller.
tools: Bash, Read, Edit
scope: CSV import and export — a mounted engine where a signed-in person sees the mapped imports and the exports the host app registers, each import backed by an importer class and each export by an exporter class the host writes, where an export is either fixed or chosen, and a chosen export lets the account save named templates of picked columns
---

This local hooks ixport into a Rails app by following the steps below exactly. It invents no step, setting or file that is not listed here.

## What ixport is

ixport is a Rails engine with two pages of work for a signed-in person. On the imports page they upload a CSV file, match its columns to a host app's fields, preview which rows will add, update or be refused, and run the import to save those records into the host app. On the exports page they download a CSV file of the host app's records, either with columns the host app has fixed in advance or from a saved template of columns their account picked. Hook it in when a Rails app needs people to load data from spreadsheets or take its data out as spreadsheets.

## Interface

- `gem "ixport"` — the Gemfile line that adds ixport to the app. It also brings in Keystone UI, which draws ixport's pages.
- `bin/rails generate ixport:install` — copies five migrations into `db/migrate/`: one that creates the `ixport_imports` table, one that creates the `ixport_import_refusals` table, one that creates the `ixport_export_templates` table, one that adds a `wallflower_task_id` column to `ixport_imports`, and one that adds an `error_message` column to `ixport_imports`.
- `bin/rails generate ixport:update` — copies the three migrations added since ixport first shipped, the one that creates the `ixport_export_templates` table, the one that adds the `wallflower_task_id` column and the one that adds the `error_message` column, into an app that installed an earlier ixport.
- `mount Ixport::Engine` — the line in `config/routes.rb` that serves ixport's pages under a path the app chooses. The imports page is at that path and the exports page is at that path followed by `/exports`.
- `Ixport.configure` — takes a block that receives the configuration object, where the app sets any of the seven settings below.
- `config.authentication_method` — the name of the controller method run before every ixport page, imports, exports and export templates alike, as a symbol. It defaults to `:authenticate_user!`.
- `config.current_person_method` — the name of the controller method that returns the signed-in person running imports and exports and saving export templates, as a symbol. It defaults to `:current_user`.
- `config.current_account_method` — the name of the controller method that returns the account the person is working in, as a symbol. It defaults to `:current_account`.
- `config.layout` — the name of the host layout ixport's pages are drawn inside, as a string. It defaults to `"application"`.
- `config.inline_row_limit` — the most data rows an uploaded import file may have, not counting its header row, as an integer. A file with more is refused on the upload page with a message giving the limit and the file's row count. It applies only while `config.background_runner` is `nil`, and it does not limit exports. It defaults to `1_000`.
- `config.background_runner` — what runs an import once the person starts it. It defaults to `nil`, which runs the import inside the request. `:wallflower` runs every import as a wallflower task. The name of a class in the app, as a string, hands every import to that class. With any value other than `nil`, every import runs through the runner whatever its size, and the inline row limit does not apply.
- `config.base_controller` — the name of the host controller ixport's controllers inherit from, as a string. Every ixport page runs that controller's own before actions first, then the sign-in check, and can call that controller's methods. It defaults to `"::ApplicationController"`.

## How to use it

1. Check whether the app already has ixport: its `Gemfile` has `gem "ixport"` and `db/migrate/` has a `create_ixport_imports` migration. If it does, go to step 13. If it does not, carry on with step 2.
2. Check that the app has Keystone UI set up: the layout ixport will use has `<%= keystone_theme_attributes %>` in its `<html>` tag. If it does not, stop and hand Keystone UI's setup to the `keystone_ui-install` local before going on, because ixport's pages are drawn with Keystone UI components and its styles.
3. Check that the app has Active Storage set up, because ixport keeps each uploaded import file as an Active Storage attachment. All three must hold:
   - `config/application.rb` loads Active Storage, either through `require "rails/all"` or through `require "active_storage/engine"`.
   - `db/schema.rb` has the `active_storage_blobs`, `active_storage_attachments` and `active_storage_variant_records` tables.
   - Each environment file in `config/environments/` sets `config.active_storage.service`, and `config/storage.yml` defines that service.

   If any is missing, tell the developer ixport cannot accept uploads without Active Storage and ask before setting it up. Where the tables are missing, setting it up means running `bin/rails active_storage:install` and then `bin/rails db:migrate`. Ask the developer which storage service each environment should use rather than picking one.
4. Add the gem to the app's `Gemfile`:
   ```ruby
   gem "ixport"
   ```
   Then run `bundle install`.
5. Run the install generator:
   ```bash
   bin/rails generate ixport:install
   ```
   It writes five files and touches no other:
   - `db/migrate/<timestamp>_create_ixport_imports.rb` creates the `ixport_imports` table with a required `key` string, a required polymorphic `person` reference, an optional polymorphic `account` reference, a `mapping` JSON column, a required `status` string defaulting to `"pending"`, required `added_count` and `updated_count` integers defaulting to `0`, and timestamps.
   - `db/migrate/<timestamp>_create_ixport_import_refusals.rb` creates the `ixport_import_refusals` table with a required `import` reference with a foreign key to `ixport_imports`, a required `row_number` integer, a required `reason` text, and timestamps.
   - `db/migrate/<timestamp>_create_ixport_export_templates.rb` creates the `ixport_export_templates` table with a required `key` string, a required `name` string, a required `columns` JSON column, a required polymorphic `person` reference, an optional polymorphic `account` reference, and timestamps.
   - `db/migrate/<timestamp>_add_wallflower_task_to_ixport_imports.rb` adds an optional `wallflower_task_id` bigint column to `ixport_imports`, with an index. It is copied whether or not the app uses wallflower.
   - `db/migrate/<timestamp>_add_error_message_to_ixport_imports.rb` adds an optional `error_message` text column to `ixport_imports`, which holds the error an import stopped on when it fails.
6. Run the migrations:
   ```bash
   bin/rails db:migrate
   ```
7. Ask the developer which path ixport's pages should live under. There is no default path. Add the mount inside `Rails.application.routes.draw` in `config/routes.rb`, using their answer:
   ```ruby
   mount Ixport::Engine => "/data_imports"
   ```
   If the app's routes put signed-in pages inside a block such as `authenticate :user do`, ask the developer whether the mount goes inside it. Do not give the mount a name with `as:`. A wallflower task links to the import's result page through the route name `ixport`, so the mount keeps that name. `bin/rails routes` lists the mount with `ixport` in its name column.
8. Ask the developer which controller ixport's pages should inherit from, and do not pick for them. The default is the app's `ApplicationController`. Where ixport's pages belong inside an area of the app with its own base controller, such as an admin area whose controller limits who may enter, naming that controller gives ixport's pages the same checks. Then read the chosen controller and the controller methods it gets from its sign-in setup, since every method named in the next step must be callable from it.
9. Compare the app's method and layout names with the defaults in the Interface section. Every default matches a Jumpstart app, so an app that uses all of the defaults needs no configuration. Where any name differs, or a method does not exist, ask the developer which method or layout to use rather than picking one:
   - The sign-in check: the method that sends a person who is not signed in to sign in, such as `:authenticate_user!` or `:require_login`.
   - The current person: the method returning the signed-in person, such as `:current_user` or `:current_member`. An import belongs to this person, and another person who opens it gets a not found response. The imports page lists only the imports this person uploaded. Each export is built for this person when it is downloaded. An export template records this person as the one who saved it. Any access rule the app gives an import or export is handed this person.
   - The current account: the method returning the team or company the person works inside, such as `:current_account` or `:current_team`. An import belongs to this account too, and the same person who opens it from another account gets a not found response. The imports page lists only the person's imports uploaded in this account. Each export is built for this account when it is downloaded. An export template belongs to this account, and every person in the account can see, download from, edit and delete it, while a person in another account gets a not found response. Any access rule the app gives an import or export is handed this account. Ask whether the app has accounts at all. ixport calls the named method on every ixport page, so an app with no accounts still needs a method of that name callable from the base controller chosen in step 8, and it returns `nil`. In an app whose method returns `nil`, every person shares every export template, and every access rule is handed `nil` as the account. Tell the developer this and ask before adding the method.
   - The layout: the file in `app/views/layouts/` that ixport's pages should be drawn inside.
10. Ask the developer how imports should run, and do not pick for them. Having wallflower in the `Gemfile` does not choose it. The three answers:
    - Inside the request: leave `config.background_runner` out. Each import file is limited to the inline row limit, and the person waits on the run page until the import finishes.
    - As a wallflower task: set `config.background_runner = :wallflower`. Running an import starts a task and takes the person to wallflower's task page, which shows the import's progress, the rows it changed and refused, and a link to the import's result page when it finishes. This needs wallflower set up in the app first:
      - The app's `Gemfile` has `gem "wallflower", ">= 0.2.0"`. If it does not, ask the developer before adding it.
      - Wallflower is installed and mounted following its own install local, or its own README where the app has no such local. ixport sends the person to wallflower's task page through the route name `wallflower`, so the mount must keep wallflower's own name and not be given a different one with `as:`. `bin/rails routes` lists the mount with `wallflower` in its name column.

      With `:wallflower` set and wallflower not loaded, the app fails to boot with a `NameError` naming `Wallflower`.
    - Through the app's own runner: set `config.background_runner` to the name of a class in the app, as a string, such as `"ImportRunner"`. Ask the developer for the name. Writing that class is out of scope for this local and belongs to `ixport-develop`, and the app fails on the first run of an import until the class exists.

    With either background answer, every import runs through the runner whatever its size, and while it runs its page shows the heading "Import running" and the message "This import is running."
11. Write only the settings that differ from the defaults into a new initializer, `config/initializers/ixport.rb`:
    ```ruby
    Ixport.configure do |config|
      config.authentication_method = :require_login
      config.current_person_method = :current_member
      config.current_account_method = :current_team
      config.layout = "back_office"
      config.inline_row_limit = 5_000
      config.background_runner = :wallflower
      config.base_controller = "BackOfficeController"
    end
    ```
    The values above are examples, and each line is written only when the developer's answer differs from the default. Ask about `config.inline_row_limit` only when imports run inside the request and the developer wants a limit other than 1,000 rows per import file, since it has no effect with a background runner.
12. Start the app and visit the mounted path while signed in. The page shows the heading "Imports" and the message "No imports are set up yet." It shows no "Your imports" list, since that list appears only once the signed-in person has uploaded an import file. Then visit the mounted path followed by `/exports`. The page shows the heading "Exports" and the message "No exports are set up yet." Visiting either while signed out sends the browser through the app's own sign-in check. The install is done, so skip step 13.
13. For an app that already has ixport, check whether `db/migrate/` has a `create_ixport_export_templates` migration, an `add_wallflower_task_to_ixport_imports` migration and an `add_error_message_to_ixport_imports` migration. If it has all three, the app is up to date and there is nothing to run. If any is missing, run `bundle update ixport`, then run the update generator and the migrations:
    ```bash
    bin/rails generate ixport:update
    bin/rails db:migrate
    ```
    Until the `error_message` migration has run, an import that fails cannot record its error and the run raises an error naming the missing column. The generator copies whichever of the three migrations step 5 describes are missing, reports each one already present as identical, and touches no other file. Then read the app's `config/initializers/ixport.rb`, or the defaults if it has none. Where the export templates migration was just added, put the current account part of step 9 to the developer, since export templates are shared by that account. Where `config.background_runner` is not set, put step 10 to the developer. Where `config.base_controller` is not set, put step 8 to the developer. Visit the mounted path followed by `/exports` while signed in and check that the page still loads. Then visit the mounted path itself and check that the imports page loads, with a "Your imports" list of the person's earlier imports when they have any. An earlier import of a kind whose access rule refuses the signed-in person is left off that list. Access rules need no migration and no setting.

## Conventions

- After installing or updating, check that `bin/rails db:migrate:status` lists the create-ixport-imports, create-ixport-import-refusals, create-ixport-export-templates, add-wallflower-task-to-ixport-imports and add-error-message-to-ixport-imports migrations as up, that `bin/rails routes` lists the mount path, and that both pages load as described in step 12. With `config.background_runner = :wallflower`, also check that `bin/rails routes` lists ixport's mount under the name `ixport` and wallflower's mount under the name `wallflower`.
- Run the install generator once, and the update generator only on an app installed with an earlier ixport. A second run of either against unchanged copies reports each migration as identical and adds nothing. If a copied migration differs from the one the generator would write, the run stops with an error naming that migration, and copies nothing after it. Do not delete or edit a copied migration once it has been run.
- An import that stops on an error is marked failed, keeps the rows it saved before stopping, and reports the error through Rails' error reporter, so it reaches whatever error service the app has subscribed there. ixport needs no setting for this, and an app with no subscriber records the error only on the import's page.
- Set `config.base_controller` only in `config/initializers/ixport.rb`. ixport reads it once, when its controllers load, so a value set anywhere later has no effect. A name that is not a controller in the app raises a `NameError` naming it when ixport's controllers load.
- When the app renames its sign-in method, its current person or account method, the layout ixport uses, its own runner class, or the base controller ixport inherits from, update the matching line in `config/initializers/ixport.rb` in the same change.
- A setting given the same value as its default is left out of the initializer. Remove a line when its value goes back to the default.
- If the app fails to boot after installing, with an error saying an ixport import or export names a class that does not exist, the app registered an import or export whose class is missing. Fixing it is out of scope for this local and belongs to `ixport-develop`.
- Every signed-in person who passes the sign-in check can use every import and export until the app gives one an access rule. Ask the developer whether some imports or exports should be limited to some people, and hand that work to `ixport-develop`.
- Setting up the imports and exports that appear on the two pages, choosing which exports are fixed and which are chosen, giving an import or export an access rule, writing the app's own background runner class, and the upload, mapping, preview, run, result, download and template pages they lead to, is out of scope for this local and belongs to `ixport-develop`.
