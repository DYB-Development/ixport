# frozen_string_literal: true

require "test_helper"

class UploadTest < ActionDispatch::IntegrationTest
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
  end

  def setup
    @person = User.create!(name: "Rep")
    ApplicationController.signed_in_user = @person
    Ixport.register_import(:products, title: "Products", importer: "UploadTest::ProductImporter")
  end

  def teardown
    ApplicationController.signed_in_user = nil
    Ixport.reset_registrations!
  end

  test "the upload page for a registered import asks for a CSV file" do
    get "/data_imports/imports/new", params: { key: "products" }

    assert_select "form[action='/data_imports/imports'] input[type=file][name=file]"
  end

  test "a person uploads a CSV for a registered mapped import" do
    post "/data_imports/imports", params: { key: "products", file: fixture_file_upload("products.csv", "text/csv") }

    assert Ixport::Import.find_by(person: @person, key: "products").file.attached?
  end
end
