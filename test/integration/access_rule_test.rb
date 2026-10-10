# frozen_string_literal: true

require "test_helper"

class AccessRuleTest < ActionDispatch::IntegrationTest
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
    Ixport.register_import(:products, title: "Products", importer: "ProductImporter", allow: ADMINS_ONLY)
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
end
