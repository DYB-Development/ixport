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
end
