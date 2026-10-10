# frozen_string_literal: true

require "test_helper"

class ExportTest < ActionDispatch::IntegrationTest
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
end
