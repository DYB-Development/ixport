# frozen_string_literal: true

require "test_helper"

class Ixport::ImportRunTest < ActiveSupport::TestCase
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
    match_on :sku

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

  class TargetProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"

    def records
      target.products
    end
  end

  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
    Ixport.register_import(:products, title: "Products", importer: "Ixport::ImportRunTest::ProductImporter")
  end

  def teardown
    Ixport.reset_registrations!
  end

  test "a row that matches no record and passes validation is added in the current account" do
    import_of("SKU,Price\nB2,200\n").run!

    assert_equal [ [ "B2", 200 ] ], @account.products.pluck(:sku, :price_cents)
  end

  test "a row that matches a record and passes validation updates it with the row's mapped values" do
    product = @account.products.create!(sku: "A1", price_cents: 100)

    import_of("SKU,Price\nA1,150\n").run!

    assert_equal 150, product.reload.price_cents
  end

  test "a row whose update fails validation is refused with its row number and reason, and its record is left unchanged" do
    product = @account.products.create!(sku: "A1", price_cents: 100)

    import = import_of("SKU,Price\nA1,lots\n")
    import.run!

    assert_equal [ 100, [ [ 2, "Price cents is not a number" ] ] ], [ product.reload.price_cents, import.refusals.pluck(:row_number, :reason) ]
  end

  test "a finished run records how many rows it added and updated" do
    @account.products.create!(sku: "A1", price_cents: 100)

    import = import_of("SKU,Price\nA1,150\nB2,200\nC3,300\n")
    import.run!

    assert_equal [ "finished", 2, 1 ], import.reload.values_at(:status, :added_count, :updated_count)
  end

  test "running a finished import again adds or changes nothing" do
    import = import_of("SKU,Price\nB2,200\nC3,lots\n")
    import.run!

    import.run!

    assert_equal [ 1, 1 ], [ @account.products.count, import.refusals.count ]
  end

  test "an import whose run raises is marked failed with the error's message and the rows saved before it stopped" do
    import = import_of("SKU,Price\nB2,200\nRAISE,300\nD4,400\n")

    import.run!

    assert_equal [ "failed", "Disk full", 1, [ "B2" ] ], [ import.reload.status, import.error_message, import.added_count, @account.products.pluck(:sku) ]
  end

  test "the error a run stopped on is reported to the host's error reporting" do
    import = import_of("SKU,Price\nRAISE,300\n")

    assert_error_reported(RuntimeError) { import.run! }
  end

  test "with no match fields named, a run leaves every existing record unchanged" do
    Ixport.register_import(:unmatched, title: "Products", importer: "Ixport::ImportRunTest::UnmatchedProductImporter")
    rent = @account.products.create!(sku: "RENT", price_cents: 1000)
    import = Ixport::Import.create!(key: "unmatched", person: @person, account: @account, mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new("SKU,Price\nA1,100\nB2,200\n"), filename: "products.csv" })

    import.run!

    assert_equal [ [ "RENT", 1000 ], 3 ], [ rent.reload.values_at(:sku, :price_cents), @account.products.count ]
  end

  test "two rows matching one record each work on their own copy, so an invalid row does not fail the valid one" do
    product = @account.products.create!(sku: "A1", price_cents: 100)
    import = import_of("SKU,Price\nA1,150\nA1,lots\n")

    import.run!

    assert_equal [ "finished", 150, [ [ 3, "Price cents is not a number" ] ] ], [ import.reload.status, product.reload.price_cents, import.refusals.pluck(:row_number, :reason) ]
  end

  test "an import with a chosen record adds its rows to that record" do
    chosen = Account.create!(name: "South")
    Ixport.register_import(:products, title: "Products", importer: "Ixport::ImportRunTest::TargetProductImporter")

    import_of("SKU,Price\nB2,200\n").tap { |import| import.update!(target: chosen) }.run!

    assert_equal [ "B2" ], chosen.products.pluck(:sku)
  end

  test "an import that refuses the whole file saves no row when any row is refused" do
    Ixport.register_import(:products, title: "Products", importer: "Ixport::ImportRunTest::ProductImporter", refuse_whole_file: true)

    import_of("SKU,Price\nB2,200\nC3,lots\nD4,400\n").run!

    assert_empty @account.products
  end

  test "an import that refuses the whole file records no rows added or updated when any row is refused" do
    Ixport.register_import(:products, title: "Products", importer: "Ixport::ImportRunTest::ProductImporter", refuse_whole_file: true)
    @account.products.create!(sku: "A1", price_cents: 100)

    import = import_of("SKU,Price\nA1,150\nB2,200\nC3,lots\n")
    import.run!

    assert_equal [ "finished", 0, 0 ], import.reload.values_at(:status, :added_count, :updated_count)
  end

  private

  def import_of(csv)
    Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new(csv), filename: "products.csv" })
  end
end
