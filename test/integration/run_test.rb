# frozen_string_literal: true

require "test_helper"

class RunTest < ActionDispatch::IntegrationTest
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
    ApplicationController.signed_in_user = @person
    ApplicationController.signed_in_account = @account
    Ixport.register_import(:products, title: "Products", importer: "RunTest::ProductImporter")
    @account.products.create!(sku: "A1", price_cents: 100)
    csv = "SKU,Price\nA1,150\nB2,200\nC3,lots\n"
    @import = Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new(csv), filename: "products.csv" })
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Ixport.reset_registrations!
  end

  test "running the import from the preview saves its rows inside the request" do
    post "/data_imports/imports/#{@import.id}/run"

    assert_equal [ [ "A1", 150 ], [ "B2", 200 ] ], @account.products.order(:sku).pluck(:sku, :price_cents)
  end

  test "the result page shows how many rows were added and updated, and each refused row with its number and reason" do
    post "/data_imports/imports/#{@import.id}/run"
    follow_redirect!

    assert_equal [ { "added" => "1", "updated" => "1" }, [ [ "4", "Price cents is not a number" ] ] ], result_on_page
  end

  test "a finished import offers no Run button" do
    post "/data_imports/imports/#{@import.id}/run"

    get "/data_imports/imports/#{@import.id}/preview"

    assert_select "form[action='/data_imports/imports/#{@import.id}/run']", count: 0
  end

  private

  def result_on_page
    counts = css_select("[data-result-count]").to_h { |count| [ count["data-result-count"], count.text.strip ] }
    refused = css_select("[data-refused-row]").map { |row| [ row.at_css("[data-row-number]").text.strip, row.at_css("[data-reason]").text.strip ] }
    [ counts, refused ]
  end
end
