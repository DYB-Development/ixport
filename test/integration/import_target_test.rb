# frozen_string_literal: true

require "test_helper"

class ImportTargetTest < ActionDispatch::IntegrationTest
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
    match_on :sku

    def records
      target.products
    end
  end

  def setup
    @account = Account.create!(name: "North")
    ApplicationController.signed_in_user = User.create!(name: "Rep")
    ApplicationController.signed_in_account = @account
    Ixport.register_import(:products, title: "Products", importer: "ImportTargetTest::ProductImporter", allow: ->(_person, account, target) { target.nil? || target.name.start_with?(account.name) })
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Ixport.reset_registrations!
  end

  test "an import opened from a link naming a chosen record adds its rows to that record" do
    chosen = Account.create!(name: "North East")

    get "/data_imports/imports/new", params: { key: "products", target: chosen.to_global_id.to_s }
    post "/data_imports/imports", params: { key: "products", target: css_select("input[name=target]").first["value"], file: fixture_file_upload("products.csv", "text/csv") }
    import = Ixport::Import.last
    patch "/data_imports/imports/#{import.id}/mapping", params: { mapping: { "0" => "sku", "1" => "price_cents" } }
    get "/data_imports/imports/#{import.id}/preview"
    post "/data_imports/imports/#{import.id}/run"

    assert_equal [ [ "A1", 100 ], [ "B2", 250 ] ], chosen.products.order(:sku).pluck(:sku, :price_cents)
  end
end
