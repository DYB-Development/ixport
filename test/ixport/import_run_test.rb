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

  private

  def importer
    ProductImporter.new(person: @person, account: @account)
  end

  def import_of(csv)
    Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new(csv), filename: "products.csv" })
  end
end
