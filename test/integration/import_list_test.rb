# frozen_string_literal: true

require "test_helper"

class ImportListTest < ActionDispatch::IntegrationTest
  def teardown
    Ixport.reset_registrations!
  end

  test "lists each registered mapped import by its title" do
    Ixport.register_import(:products, title: "Products", importer: "ProductImporter")
    Ixport.register_import(:customers, title: "Customers", importer: "CustomerImporter")

    get "/data_imports"

    assert_equal [ "Products", "Customers" ], css_select("[data-import]").map { |entry| entry.text.strip }
  end
end
