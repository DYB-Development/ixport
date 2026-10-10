# ixport

CSV import and export for Rails apps. An app registers the kinds of CSV a person can import and the fields each one maps to, and the CSV downloads a person can export.

## Installation

Add the gem and run its install generator, which copies the migrations for its tables:

```ruby
gem "ixport"
```

```bash
bundle install
bin/rails generate ixport:install
bin/rails db:migrate
```

After updating the gem, run its update generator to copy any migrations added since it was installed, then migrate:

```bash
bin/rails generate ixport:update
bin/rails db:migrate
```

Mount the engine at the path its pages should live under:

```ruby
mount Ixport::Engine => "/data_imports"
```

## Configuration

Every setting has a default that matches a Jumpstart app, so set only what differs in your app:

```ruby
Ixport.configure do |config|
  config.authentication_method = :authenticate_user! # runs before every ixport page
  config.current_person_method = :current_user       # returns the person who starts and views imports
  config.current_account_method = :current_account   # returns the account an import belongs to
  config.layout = "application"                      # the layout ixport's pages are drawn in
  config.inline_row_limit = 1_000                    # the most rows an import may have when it runs inside the request
  config.background_runner = nil                     # :wallflower, or the name of the app's own runner class
end
```

## Mapped imports and importers

A mapped import is a kind of CSV a person can import into one of the app's records. Register each one in an initializer with its key, its title and the name of its importer class:

```ruby
Ixport.register_import :products, title: "Products", importer: "ProductImporter"
```

An app whose registered importer class does not exist fails to boot, with a message naming the class.

The engine's root page lists every registered import by its title, each linking to its upload page.

An importer lists the fields a person maps the file's columns to, each with the label the person sees. It names the one field rows are matched on, and the records a row may match, which it reaches through the `person` and `account` the import is for:

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

Each field's key is the record's attribute name. ixport looks up every match value in the file with one query against `records`. A row whose match value matches one of those records updates it, and a row that matches nothing adds a new record built from `records`. A row whose match value is blank, or whose file has no column mapped to the match field, always adds a record.

## Uploading and mapping a file

From the engine's root page, a person picks a registered import and uploads a CSV for it. The upload is refused, with a message on the upload page, when the file has no header row, or, in an app with no background runner, has more rows than `config.inline_row_limit`.

After uploading, the person matches each column of the file's header row to one of the importer's fields, by its label, or skips it. Saving the mapping moves them on to the preview.

The preview shows how many rows will add a record, update one or be refused, before anything is saved. It lists each row that will update a record and each refused row, by its row number in the file, with the reason the record gives for a refusal. A row is refused when the record it builds is not valid. Viewing the preview saves nothing, and the person can go back from it to change the mapping.

## Running an import

The person runs the import from the preview. With no background runner configured, it runs inside the request. Each row that passes the record's validations is saved, updating the record it matches or adding a new one. Each row that fails them is refused and kept with its row number and reason, and the record it matched is left unchanged.

The import's result page then shows how many rows were added and how many updated, and lists each refused row. It shows the same thing on every later visit. A finished import offers no Run button, its preview leads to its result page, and running it again adds or changes nothing.

An import belongs to the person and account that uploaded it, and anyone else gets not found when they open it.

The engine's root page also lists the person's imports in the current account, newest first. Each shows its title, file name, status and date, and its added, updated and refused counts once it has run. Each opens the page for the step the import has reached: its mapping, its preview, or its result.

## Running imports in the background

With `config.background_runner` set, every import runs through the runner, whatever its size, and the inline row limit does not apply. Having wallflower loaded does not set it.

Set it to `:wallflower` to run imports as wallflower tasks. Running an import then starts a task and takes the person to the task page, which shows its progress, the rows it changed and refused, and a link to the import's result page when it finishes. The host must mount wallflower under its own name. Run `bin/rails generate ixport:update` after updating, for the migration that links an import to its task.

Set it to the name of the app's own runner class to run imports another way. ixport hands each import to the class's `enqueue`, and the runner later runs it with `Ixport.run_import`. Until then the import's page shows it as running:

```ruby
class ImportRunner
  def self.enqueue(import)
    RunImportJob.perform_later(import.id)
  end
end

class RunImportJob < ApplicationJob
  def perform(import_id)
    Ixport.run_import(Ixport::Import.find(import_id))
  end
end
```

## Fixed exports

A fixed export is a CSV download whose columns the app chooses. Register each one in an initializer with its key, its title and the name of its exporter class:

```ruby
Ixport.register_export :products, title: "Products", exporter: "ProductExporter"
```

An app whose registered exporter class does not exist fails to boot, with a message naming the class.

An exporter lists its columns, each with the label that heads it in the CSV. A column can come from a related record by naming the association it comes through. `records` returns the records to export, reached through the `person` and `account` the download is for:

```ruby
class ProductExporter < Ixport::Exporter
  column :sku, label: "SKU"
  column :price_cents, label: "Price"
  column :name, label: "Category", through: :category

  def records
    account.products.includes(:category)
  end
end
```

The engine's exports page, at `exports` under the mount path, lists every registered export by its title, each linking to its download. The download's header row is the exporter's column labels in order, followed by one row per record.

## Chosen exports and templates

An export registered with `chosen: true` lets a person pick its columns instead of taking all of them. It uses the same kind of exporter:

```ruby
Ixport.register_export :products, title: "Products", exporter: "ProductExporter", chosen: true
```

On the exports page, a chosen export lists its saved templates and offers New template. A template has a name and the exporter's columns picked in order, and downloading it gives a CSV of only those columns. Every member of an account sees, downloads, edits and deletes the account's templates, and another account's templates answer not found. A template whose column the exporter no longer lists still downloads, without that column.

## Claude Code agents

ixport ships its own Claude Code agents through [the_local](https://github.com/DYB-Development/the_local). An app that lists ixport in its Gemfile and runs `bundle exec the_local install` gets them in `.claude/agents/`.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
