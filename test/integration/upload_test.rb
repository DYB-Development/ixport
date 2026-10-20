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
    Ixport.reset_configuration!
  end

  test "the upload page for a registered import asks for a CSV file" do
    get "/data_imports/imports/new", params: { key: "products" }

    assert_select "form[action='/data_imports/imports'] input[type=file][name=file]"
  end

  test "the upload page opened with a chosen record carries that record into the upload" do
    chosen = Account.create!(name: "North")

    get "/data_imports/imports/new", params: { key: "products", target: chosen.to_global_id.to_s }

    assert_select "form input[type=hidden][name=target][value='#{chosen.to_global_id}']"
  end

  test "a person uploads a CSV for a registered mapped import" do
    post "/data_imports/imports", params: { key: "products", file: fixture_file_upload("products.csv", "text/csv") }

    assert Ixport::Import.find_by(person: @person, key: "products").file.attached?
  end

  test "after uploading, the person is taken to map the file's columns" do
    post "/data_imports/imports", params: { key: "products", file: fixture_file_upload("products.csv", "text/csv") }

    assert_redirected_to "/data_imports/imports/#{Ixport::Import.last.id}/mapping"
  end

  test "a file with no header row is refused on the upload page" do
    post "/data_imports/imports", params: { key: "products", file: fixture_file_upload("empty.csv", "text/csv") }

    assert_select "[data-upload-error]", text: "This file has no header row."
  end

  test "a file with more rows than the inline row limit is refused with the limit and its row count" do
    Ixport.configure { |config| config.inline_row_limit = 2 }

    post "/data_imports/imports", params: { key: "products", file: fixture_file_upload("three_rows.csv", "text/csv") }

    assert_select "[data-upload-error]", text: "This file has 3 rows, and the most an import can have is 2."
  end

  test "the upload page for a key no import is registered under answers not found" do
    get "/data_imports/imports/new", params: { key: "invoices" }

    assert_response :not_found
  end

  test "an upload for a key no import is registered under answers not found" do
    post "/data_imports/imports", params: { key: "invoices", file: fixture_file_upload("products.csv", "text/csv") }

    assert_response :not_found
  end

  test "with a background runner configured, a file over the inline row limit is accepted" do
    Ixport.configure do |config|
      config.inline_row_limit = 2
      config.background_runner = :wallflower
    end

    post "/data_imports/imports", params: { key: "products", file: fixture_file_upload("three_rows.csv", "text/csv") }

    assert_redirected_to "/data_imports/imports/#{Ixport::Import.last.id}/mapping"
  end

  test "a file whose quoting is broken is refused with a message naming the line where reading stopped" do
    post "/data_imports/imports", params: { key: "products", file: fixture_file_upload("broken_quotes.csv", "text/csv") }

    assert_select "[data-upload-error]", text: "This file could not be read past line 2. Check the quotes on that line."
  end

  test "a file that is not UTF-8 is refused with a message saying so" do
    post "/data_imports/imports", params: { key: "products", file: fixture_file_upload("latin1.csv", "text/csv") }

    assert_select "[data-upload-error]", text: "This file is not UTF-8 text. Save it as UTF-8 and upload it again."
  end
end
