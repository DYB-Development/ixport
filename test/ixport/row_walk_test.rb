# frozen_string_literal: true

require "test_helper"

class Ixport::RowWalkTest < ActiveSupport::TestCase
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
    match_on :sku

    def records
      account.products
    end
  end

  class ProductBySkuAndPriceImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
    match_on :sku, :price_cents

    def records
      account.products
    end
  end

  class UnmatchedProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"

    def records
      account.products
    end
  end

  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
  end

  test "a row whose match value matches no record will add one" do
    walk = walk_of("SKU,Price\nA1,100\n", { "0" => "sku", "1" => "price_cents" })

    assert_equal [ :add ], walk.rows.map(&:outcome)
  end

  test "a row whose match value matches one of the importer's records will update it" do
    product = @account.products.create!(sku: "A1", price_cents: 100)

    walk = walk_of("SKU,Price\nA1,250\n", { "0" => "sku", "1" => "price_cents" })

    assert_equal [ [ :update, product ] ], walk.rows.map { |row| [ row.outcome, row.record ] }
  end

  test "a row whose record is not valid will be refused with the reason the record gives" do
    walk = walk_of("SKU,Price\nA1,lots\n", { "0" => "sku", "1" => "price_cents" })

    assert_equal [ [ :refused, "Price cents is not a number" ] ], walk.rows.map { |row| [ row.outcome, row.reason ] }
  end

  test "with no column mapped to the match field, every row that passes will add a record" do
    @account.products.create!(sku: "", price_cents: 100)

    walk = walk_of("SKU,Price\nA1,250\n", { "1" => "price_cents" })

    assert_equal [ :add ], walk.rows.map(&:outcome)
  end

  test "a row equal to a record on every field the importer matches on updates it" do
    product = @account.products.create!(sku: "A1", price_cents: 100)

    walk = walk_of("SKU,Price\nA1,100\n", { "0" => "sku", "1" => "price_cents" }, ProductBySkuAndPriceImporter)

    assert_equal [ [ :update, product ] ], walk.rows.map { |row| [ row.outcome, row.record ] }
  end

  test "a row that differs from every record on one of the matched fields adds a record" do
    @account.products.create!(sku: "A1", price_cents: 100)

    walk = walk_of("SKU,Price\nA1,200\n", { "0" => "sku", "1" => "price_cents" }, ProductBySkuAndPriceImporter)

    assert_equal [ :add ], walk.rows.map(&:outcome)
  end

  test "matched values are compared as the record's own type" do
    product = @account.products.create!(sku: "A1", price_cents: 100)

    walk = walk_of("SKU,Price\nA1,100.0\n", { "0" => "sku", "1" => "price_cents" }, ProductBySkuAndPriceImporter)

    assert_equal [ [ :update, product ] ], walk.rows.map { |row| [ row.outcome, row.record ] }
  end

  test "with no match fields named, every row adds a new record" do
    @account.products.create!(sku: "A1", price_cents: 100)

    walk = walk_of("SKU,Price\nA1,100\nB2,200\n", { "0" => "sku", "1" => "price_cents" }, UnmatchedProductImporter)

    assert_equal [ [ :add, true ], [ :add, true ] ], walk.rows.map { |row| [ row.outcome, row.record.new_record? ] }
  end

  private

  def walk_of(csv, mapping, importer_class = ProductImporter)
    import = Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: mapping, file: { io: StringIO.new(csv), filename: "products.csv" })
    Ixport::RowWalk.new(import, importer_class.new(person: @person, account: @account))
  end
end
