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

  test "the exports page loads when a saved template's key is no longer registered" do
    Ixport::ExportTemplate.create!(key: "retired_products", name: "Old prices", columns: [ "sku" ], person: @person, account: @account)

    get "/data_imports/exports"

    assert_response :success
  end

  test "the exports page leaves out a saved template whose key is no longer registered" do
    Ixport::ExportTemplate.create!(key: "products", name: "Prices", columns: [ "sku" ], person: @person, account: @account)
    Ixport::ExportTemplate.create!(key: "retired_products", name: "Old prices", columns: [ "sku" ], person: @person, account: @account)

    get "/data_imports/exports"

    assert_equal [ "Prices" ], css_select("[data-export-template]").map { |template| template.text.strip }
  end

  test "a template's download page returns not found once its key is no longer registered" do
    template = Ixport::ExportTemplate.create!(key: "retired_products", name: "Old prices", columns: [ "sku" ], person: @person, account: @account)

    get "/data_imports/export_templates/#{template.id}"

    assert_response :not_found
  end

  test "a template's edit page returns not found once its key is no longer registered" do
    template = Ixport::ExportTemplate.create!(key: "retired_products", name: "Old prices", columns: [ "sku" ], person: @person, account: @account)

    get "/data_imports/export_templates/#{template.id}/edit"

    assert_response :not_found
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

  test "the new template page offers one column choice per position, each listing the exporter's columns by label" do
    get "/data_imports/exports/products/templates/new"

    choices = [ "None", "SKU", "Price", "Account" ]
    assert_equal [ choices, choices, choices ], css_select("form select[name='columns[]']").map { |select| select.css("option").map { |option| option.text.strip } }
  end

  test "downloading a template gives a CSV with only the picked columns, in the picked order" do
    @account.products.create!(sku: "A1", price_cents: 100)
    template = Ixport::ExportTemplate.create!(key: "products", name: "Prices", columns: [ "price_cents", "sku" ], person: @person, account: @account)

    get "/data_imports/export_templates/#{template.id}"

    assert_equal "Price,SKU\n100,A1\n", response.body
  end

  test "a template whose column the exporter no longer lists still downloads, without that column" do
    @account.products.create!(sku: "A1", price_cents: 100)
    template = Ixport::ExportTemplate.create!(key: "products", name: "Prices", columns: [ "cost_cents", "sku" ], person: @person, account: @account)

    get "/data_imports/export_templates/#{template.id}"

    assert_equal "SKU\nA1\n", response.body
  end

  test "a template of another account answers not found" do
    template = Ixport::ExportTemplate.create!(key: "products", name: "Prices", columns: [ "sku" ], person: @person, account: Account.create!(name: "South"))

    get "/data_imports/export_templates/#{template.id}"

    assert_response :not_found
  end

  test "every member of the account sees the account's templates on the exports page, and no other account's" do
    Ixport::ExportTemplate.create!(key: "products", name: "Prices", columns: [ "sku" ], person: User.create!(name: "Teammate"), account: @account)
    Ixport::ExportTemplate.create!(key: "products", name: "South prices", columns: [ "sku" ], person: @person, account: Account.create!(name: "South"))

    get "/data_imports/exports"

    assert_equal [ "Prices" ], css_select("[data-export-template]").map { |template| template.text.strip }
  end

  test "a person edits a template's name and columns" do
    template = Ixport::ExportTemplate.create!(key: "products", name: "Prices", columns: [ "sku" ], person: @person, account: @account)

    patch "/data_imports/export_templates/#{template.id}", params: { name: "Price list", columns: [ "sku", "price_cents" ] }

    assert_equal [ "Price list", [ "sku", "price_cents" ] ], template.reload.then { |saved| [ saved.name, saved.columns ] }
  end

  test "a person deletes a template" do
    template = Ixport::ExportTemplate.create!(key: "products", name: "Prices", columns: [ "sku" ], person: @person, account: @account)

    delete "/data_imports/export_templates/#{template.id}"

    assert_not Ixport::ExportTemplate.exists?(template.id)
  end

  test "the edit page shows the template's name and its columns picked in order" do
    template = Ixport::ExportTemplate.create!(key: "products", name: "Prices", columns: [ "price_cents", "sku" ], person: @person, account: @account)

    get "/data_imports/export_templates/#{template.id}/edit"

    assert_equal [ "Prices", [ "price_cents", "sku", nil ] ], [ css_select("form input[name=name]").first["value"], css_select("form select[name='columns[]']").map { |select| select.at_css("option[selected]")&.[]("value") } ]
  end
end
