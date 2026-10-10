# frozen_string_literal: true

require "test_helper"

class ExportTest < ActionDispatch::IntegrationTest
  class ProductExporter < Ixport::Exporter
    column :sku, label: "SKU"
    column :price_cents, label: "Price"

    def records
      account.products.order(:sku)
    end
  end

  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
    ApplicationController.signed_in_user = @person
    ApplicationController.signed_in_account = @account
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Ixport.reset_registrations!
  end

  test "the exports page lists each registered export by its title" do
    Ixport.register_export(:products, title: "Products", exporter: "ProductExporter")
    Ixport.register_export(:customers, title: "Customers", exporter: "CustomerExporter")

    get "/data_imports/exports"

    assert_equal [ "Products", "Customers" ], css_select("[data-export]").map { |entry| entry.text.strip }
  end

  test "downloading a fixed export gives a CSV of the exporter's column labels and one row per record" do
    Ixport.register_export(:products, title: "Products", exporter: "ExportTest::ProductExporter")
    @account.products.create!(sku: "A1", price_cents: 100)
    @account.products.create!(sku: "B2", price_cents: 200)

    get "/data_imports/exports/products"

    assert_equal "SKU,Price\nA1,100\nB2,200\n", response.body
  end

  test "downloading an export under a key no export is registered under answers not found" do
    get "/data_imports/exports/invoices"

    assert_response :not_found
  end
end
