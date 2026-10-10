# frozen_string_literal: true

require "test_helper"

class Ixport::ExporterTest < ActiveSupport::TestCase
  class ProductExporter < Ixport::Exporter
    column :sku, label: "SKU"
    column :price_cents, label: "Price"
  end

  test "an exporter lists its columns with the labels a person sees" do
    assert_equal [ [ :sku, "SKU" ], [ :price_cents, "Price" ] ], ProductExporter.columns.map { |column| [ column.key, column.label ] }
  end
end
