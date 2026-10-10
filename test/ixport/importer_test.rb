# frozen_string_literal: true

require "test_helper"

class Ixport::ImporterTest < ActiveSupport::TestCase
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
    match_on :sku
  end

  class MatchingProductImporter < ProductImporter
    def find_existing(row)
      Object.new if row[:sku] == "A1"
    end
  end

  test "an importer lists its fields with the labels a person sees" do
    assert_equal [ [ :sku, "SKU" ], [ :price_cents, "Price" ] ], ProductImporter.fields.map { |field| [ field.key, field.label ] }
  end

  test "an importer declares the one field rows are matched on" do
    assert_equal :sku, ProductImporter.match_field
  end

  test "a row that matches no existing record is treated as new" do
    assert ProductImporter.new.new_row?({ sku: "A1" })
  end

  test "a row the importer matches to an existing record is not new" do
    assert_not MatchingProductImporter.new.new_row?({ sku: "A1" })
  end
end
