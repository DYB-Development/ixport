# frozen_string_literal: true

require "test_helper"

class ExportTemplateTest < ActionDispatch::IntegrationTest
  class ProductExporter < Ixport::Exporter
    column :sku, label: "SKU"
    column :price_cents, label: "Price"
    column :name, label: "Account", through: :account

    def records
      account.products.order(:sku)
    end
  end

  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
    ApplicationController.signed_in_user = @person
    ApplicationController.signed_in_account = @account
    Ixport.register_export(:products, title: "Products", exporter: "ExportTemplateTest::ProductExporter", chosen: true)
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Ixport.reset_registrations!
  end

  test "a person saves a named template of picked columns in the order they picked them" do
    post "/data_imports/exports/products/templates", params: { name: "Prices", columns: [ "price_cents", "", "sku" ] }

    assert_equal [ "Prices", [ "price_cents", "sku" ], @account ], Ixport::ExportTemplate.last.then { |template| [ template.name, template.columns, template.account ] }
  end

  test "a template keeps only columns the exporter lists" do
    post "/data_imports/exports/products/templates", params: { name: "Prices", columns: [ "price_cents", "password_digest" ] }

    assert_equal [ "price_cents" ], Ixport::ExportTemplate.last.columns
  end

  test "a template cannot be saved for a fixed export" do
    Ixport.register_export(:accounts, title: "Accounts", exporter: "ExportTemplateTest::ProductExporter")

    post "/data_imports/exports/accounts/templates", params: { name: "Names", columns: [ "sku" ] }

    assert_response :not_found
  end
end
