# frozen_string_literal: true

require "test_helper"

class PreviewTest < ActionDispatch::IntegrationTest
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

  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
    ApplicationController.signed_in_user = @person
    ApplicationController.signed_in_account = @account
    Ixport.register_import(:products, title: "Products", importer: "PreviewTest::ProductImporter")
    @account.products.create!(sku: "A1", price_cents: 100)
    csv = "SKU,Price\nA1,150\nB2,200\nC3,lots\nD4,400\n"
    @import = Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new(csv), filename: "products.csv" })
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Ixport.reset_registrations!
  end

  test "shows how many rows will add, update and be refused" do
    get "/data_imports/imports/#{@import.id}/preview"

    assert_equal({ "add" => "2", "update" => "1", "refused" => "1" }, css_select("[data-count]").to_h { |count| [ count["data-count"], count.text.strip ] })
  end

  test "lists each row that will update a record, with its row number in the file" do
    get "/data_imports/imports/#{@import.id}/preview"

    assert_equal [ "2" ], css_select("[data-update-row] [data-row-number]").map { |number| number.text.strip }
  end

  test "lists each refused row with its row number in the file and the reason the record gives" do
    get "/data_imports/imports/#{@import.id}/preview"

    assert_equal [ [ "4", "Price cents is not a number" ] ], css_select("[data-refused-row]").map { |row| [ row.at_css("[data-row-number]").text.strip, row.at_css("[data-reason]").text.strip ] }
  end

  test "viewing the preview adds or changes no record in the host app" do
    get "/data_imports/imports/#{@import.id}/preview"

    assert_equal [ [ "A1", 100 ] ], Product.pluck(:sku, :price_cents)
  end

  test "the person can go back from the preview to change the mapping" do
    get "/data_imports/imports/#{@import.id}/preview"

    assert_select "a[href='/data_imports/imports/#{@import.id}/mapping']"
  end

  test "the preview offers a Run import button" do
    get "/data_imports/imports/#{@import.id}/preview"

    assert_select "form[action='/data_imports/imports/#{@import.id}/run'] button[type=submit]", text: "Run import"
  end

  test "the preview counts a row matched on several fields as an update" do
    Ixport.register_import(:prices, title: "Prices", importer: "PreviewTest::ProductBySkuAndPriceImporter")
    import = Ixport::Import.create!(key: "prices", person: @person, account: @account, mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new("SKU,Price\nA1,100\nA1,999\n"), filename: "prices.csv" })

    get "/data_imports/imports/#{import.id}/preview"

    assert_equal({ "add" => "1", "update" => "1", "refused" => "0" }, css_select("[data-count]").to_h { |count| [ count["data-count"], count.text.strip ] })
  end

  test "an import that refuses the whole file offers no Run import button while any row is refused" do
    Ixport.register_import(:products, title: "Products", importer: "PreviewTest::ProductImporter", refuse_whole_file: true)

    get "/data_imports/imports/#{@import.id}/preview"

    assert_select "form[action='/data_imports/imports/#{@import.id}/run']", count: 0
  end
end
