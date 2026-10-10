# frozen_string_literal: true

require "test_helper"

class Ixport::ImporterTest < ActiveSupport::TestCase
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
  end

  test "an importer lists its fields with the labels a person sees" do
    assert_equal [ [ :sku, "SKU" ], [ :price_cents, "Price" ] ], ProductImporter.fields.map { |field| [ field.key, field.label ] }
  end

  test "a row that matches no existing record is treated as new" do
    assert ProductImporter.new.new_row?({ sku: "A1" })
  end
end
