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

  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
  end

  test "a row that matches no record and passes validation is added in the current account" do
    import_of("SKU,Price\nB2,200\n").run!(importer)

    assert_equal [ [ "B2", 200 ] ], @account.products.pluck(:sku, :price_cents)
  end

  test "a row that matches a record and passes validation updates it with the row's mapped values" do
    product = @account.products.create!(sku: "A1", price_cents: 100)

    import_of("SKU,Price\nA1,150\n").run!(importer)

    assert_equal 150, product.reload.price_cents
  end

  test "a row whose update fails validation is refused with its row number and reason, and its record is left unchanged" do
    product = @account.products.create!(sku: "A1", price_cents: 100)

    import = import_of("SKU,Price\nA1,lots\n")
    import.run!(importer)

    assert_equal [ 100, [ [ 2, "Price cents is not a number" ] ] ], [ product.reload.price_cents, import.refusals.pluck(:row_number, :reason) ]
  end

  test "a finished run records how many rows it added and updated" do
    @account.products.create!(sku: "A1", price_cents: 100)

    import = import_of("SKU,Price\nA1,150\nB2,200\nC3,300\n")
    import.run!(importer)

    assert_equal [ "finished", 2, 1 ], import.reload.values_at(:status, :added_count, :updated_count)
  end

  test "running a finished import again adds or changes nothing" do
    import = import_of("SKU,Price\nB2,200\nC3,lots\n")
    import.run!(importer)

    import.run!(importer)

    assert_equal [ 1, 1 ], [ @account.products.count, import.refusals.count ]
  end

  private

  def importer
    ProductImporter.new(person: @person, account: @account)
  end

  def import_of(csv)
    Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new(csv), filename: "products.csv" })
  end
end
