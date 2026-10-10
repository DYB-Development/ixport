# frozen_string_literal: true

require "test_helper"

class AccessRuleTest < ActionDispatch::IntegrationTest
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    match_on :sku

    def records
      account.products
    end
  end

  class ProductExporter < Ixport::Exporter
    column :sku, label: "SKU"

    def records
      account.products
    end
  end

  ADMINS_ONLY = ->(person, _account) { person.name == "Admin" }

  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
    ApplicationController.signed_in_user = @person
    ApplicationController.signed_in_account = @account
    Ixport.register_import(:products, title: "Products", importer: "AccessRuleTest::ProductImporter", allow: ADMINS_ONLY)
    Ixport.register_import(:customers, title: "Customers", importer: "CustomerImporter")
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Ixport.reset_registrations!
  end

  test "a person the rule refuses does not see that import listed" do
    get "/data_imports"

    assert_equal [ "Customers" ], css_select("[data-import]").map { |entry| entry.text.strip }
  end

  test "a person the rule refuses gets not found for that import's upload" do
    get "/data_imports/imports/new", params: { key: "products" }

    assert_response :not_found
  end

  test "a person the rule refuses gets not found for that kind's existing import pages" do
    import = Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: { "0" => "sku" }, file: { io: StringIO.new("SKU\nA1\n"), filename: "products.csv" })

    responses = [ "mapping", "preview", "" ].map do |step|
      get "/data_imports/imports/#{import.id}/#{step}".chomp("/")
      response.status
    end

    assert_equal [ 404, 404, 404 ], responses
  end

  test "a person the rule refuses does not see their past imports of that kind" do
    Ixport.register_import(:customers, title: "Customers", importer: "AccessRuleTest::ProductImporter")
    [ "products", "customers" ].each do |key|
      Ixport::Import.create!(key: key, person: @person, account: @account, file: { io: StringIO.new("SKU\nA1\n"), filename: "#{key}.csv" })
    end

    get "/data_imports"

    assert_equal [ "customers.csv" ], css_select("[data-past-import] [data-file-name]").map { |name| name.text.strip }
  end
end
