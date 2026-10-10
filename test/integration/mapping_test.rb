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

  test "each column offers the record's fields by their labels, or Skip" do
    get "/data_imports/imports/#{@import.id}/mapping"

    assert_equal [ "Skip", "SKU", "Price" ], css_select("[data-column] select[name='mapping[1]'] option").map { |option| option.text.strip }
  end

  test "saves which field each column maps to, leaving out skipped columns" do
    patch "/data_imports/imports/#{@import.id}/mapping", params: { mapping: { "0" => "sku", "1" => "" } }

    assert_equal({ "0" => "sku" }, @import.reload.mapping)
  end

  test "after saving the mapping, the person moves on to the preview" do
    patch "/data_imports/imports/#{@import.id}/mapping", params: { mapping: { "0" => "sku" } }

    assert_redirected_to "/data_imports/imports/#{@import.id}/preview"
  end

  test "the mapping page saves through a form with a Save mapping button" do
    get "/data_imports/imports/#{@import.id}/mapping"

    assert_select "form[action='/data_imports/imports/#{@import.id}/mapping'] button[type=submit]", text: "Save mapping"
  end
end
