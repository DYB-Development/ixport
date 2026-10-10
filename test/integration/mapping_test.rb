# frozen_string_literal: true

require "test_helper"

class MappingTest < ActionDispatch::IntegrationTest
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
  end

  def setup
    @person = User.create!(name: "Rep")
    ApplicationController.signed_in_user = @person
    Ixport.register_import(:products, title: "Products", importer: "MappingTest::ProductImporter")
    @import = Ixport::Import.create!(key: "products", person: @person, file: { io: file_fixture("products.csv").open, filename: "products.csv" })
  end

  def teardown
    ApplicationController.signed_in_user = nil
    Ixport.reset_registrations!
  end

  test "shows one line per column in the file's header row" do
    get "/data_imports/imports/#{@import.id}/mapping"

    assert_equal [ "SKU", "Price" ], css_select("[data-column] [data-column-name]").map { |name| name.text.strip }
  end
end
