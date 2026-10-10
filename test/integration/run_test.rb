# frozen_string_literal: true

require "test_helper"

class RunTest < ActionDispatch::IntegrationTest
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
    match_on :sku

    def records
      account.products
    end
  end

  class RecordingRunner
    cattr_accessor :enqueued, default: []

    def self.enqueue(import)
      enqueued << import
    end
  end

  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
    ApplicationController.signed_in_user = @person
    ApplicationController.signed_in_account = @account
    Ixport.register_import(:products, title: "Products", importer: "RunTest::ProductImporter")
    @account.products.create!(sku: "A1", price_cents: 100)
    csv = "SKU,Price\nA1,150\nB2,200\nC3,lots\n"
    @import = Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new(csv), filename: "products.csv" })
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Ixport.reset_registrations!
    Ixport.reset_configuration!
    Wallflower.reset_kinds!
  end

  test "running the import from the preview saves its rows inside the request" do
    post "/data_imports/imports/#{@import.id}/run"

    assert_equal [ [ "A1", 150 ], [ "B2", 200 ] ], @account.products.order(:sku).pluck(:sku, :price_cents)
  end

  test "the result page shows how many rows were added and updated, and each refused row with its number and reason" do
    post "/data_imports/imports/#{@import.id}/run"
    follow_redirect!

    assert_equal [ { "added" => "1", "updated" => "1" }, [ [ "4", "Price cents is not a number" ] ] ], result_on_page
  end

  test "a finished import offers no Run button" do
    post "/data_imports/imports/#{@import.id}/run"

    get "/data_imports/imports/#{@import.id}/preview"

    assert_select "form[action='/data_imports/imports/#{@import.id}/run']", count: 0
  end

  test "a repeated run request adds or changes nothing" do
    post "/data_imports/imports/#{@import.id}/run"
    Product.find_by(sku: "A1").update!(price_cents: 999)

    post "/data_imports/imports/#{@import.id}/run"

    assert_equal [ [ "A1", 999 ], [ "B2", 200 ] ], @account.products.order(:sku).pluck(:sku, :price_cents)
  end

  test "returning to the result page later shows the same counts and refused rows" do
    post "/data_imports/imports/#{@import.id}/run"
    reset!
    ApplicationController.signed_in_user = @person
    ApplicationController.signed_in_account = @account

    get "/data_imports/imports/#{@import.id}"

    assert_equal [ { "added" => "1", "updated" => "1" }, [ [ "4", "Price cents is not a number" ] ] ], result_on_page
  end

  test "the result page of an import that has not run leads to its preview" do
    get "/data_imports/imports/#{@import.id}"

    assert_redirected_to "/data_imports/imports/#{@import.id}/preview"
  end

  test "with wallflower as the runner, running an import starts a wallflower task and opens its page" do
    use_wallflower

    post "/data_imports/imports/#{@import.id}/run"

    task = Wallflower::Task.last
    assert_equal [ "ixport_import", { "import_id" => @import.id }, "/background/tasks/#{task.id}" ], [ task.kind, task.params, URI(response.location).path ]
  end

  test "with wallflower loaded but no runner configured, an import still runs inside the request" do
    post "/data_imports/imports/#{@import.id}/run"

    assert_equal [ 0, "finished" ], [ Wallflower::Task.count, @import.reload.status ]
  end

  test "a host's own runner configured in place of wallflower is handed every mapped import" do
    RecordingRunner.enqueued = []
    Ixport.configure { |config| config.background_runner = "RunTest::RecordingRunner" }

    post "/data_imports/imports/#{@import.id}/run"

    assert_equal [ @import ], RecordingRunner.enqueued
  end

  test "while a host's own runner works, the import's page shows it as running" do
    Ixport.configure { |config| config.background_runner = "RunTest::RecordingRunner" }

    post "/data_imports/imports/#{@import.id}/run"
    follow_redirect!

    assert_select "[data-import-running]", text: "This import is running."
  end

  private

  def use_wallflower
    Ixport.configure { |config| config.background_runner = :wallflower }
    Ixport.install_background_runner!
  end

  def result_on_page
    counts = css_select("[data-result-count]").to_h { |count| [ count["data-result-count"], count.text.strip ] }
    refused = css_select("[data-refused-row]").map { |row| [ row.at_css("[data-row-number]").text.strip, row.at_css("[data-reason]").text.strip ] }
    [ counts, refused ]
  end
end
