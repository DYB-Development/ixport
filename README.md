# ixport

CSV import and export for Rails apps. An app registers the kinds of CSV a person can import and the fields each one maps to.

## Installation

Add the gem and run its install generator, which copies the migration for its imports table:

```ruby
gem "ixport"
```

```bash
bundle install
bin/rails generate ixport:install
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
end
```

## Mapped imports and importers

A mapped import is a kind of CSV a person can import into one of the app's records. Register each one in an initializer with its key, its title and the name of its importer class:

```ruby
Ixport.register_import :products, title: "Products", importer: "ProductImporter"
```

An app whose registered importer class does not exist fails to boot, with a message naming the class.

The engine's root page lists every registered import by its title, each linking to its upload page.

An importer lists the fields a person maps the file's columns to, each with the label the person sees, and says which existing record a row matches:

```ruby
class ProductImporter < Ixport::Importer
  field :sku, label: "SKU"
  field :price_cents, label: "Price"

  def find_existing(row)
    Product.find_by(sku: row[:sku])
  end
end
```

A row whose `find_existing` returns a record is matched to that record, and a row that matches nothing is new. An importer that does not define `find_existing` treats every row as new.

## Uploading and mapping a file

From the engine's root page, a person picks a registered import and uploads a CSV for it. The upload is refused, with a message on the upload page, when the file has no header row or has more rows than `config.inline_row_limit`.

After uploading, the person matches each column of the file's header row to one of the importer's fields, by its label, or skips it. Saving the mapping moves them on to the preview.

An import belongs to the person and account that uploaded it, and anyone else gets not found when they open it.

## Claude Code agents

ixport ships its own Claude Code agents through [the_local](https://github.com/DYB-Development/the_local). An app that lists ixport in its Gemfile and runs `bundle exec the_local install` gets them in `.claude/agents/`.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
