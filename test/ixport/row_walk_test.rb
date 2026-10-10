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

  private

  def walk_of(csv, mapping)
    import = Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: mapping, file: { io: StringIO.new(csv), filename: "products.csv" })
    Ixport::RowWalk.new(import, ProductImporter.new(person: @person, account: @account))
  end
end
