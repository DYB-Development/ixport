# frozen_string_literal: true

require "test_helper"

class PreviewAndRunAgreeTest < ActionDispatch::IntegrationTest
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
    Ixport.register_import(:products, title: "Products", importer: "PreviewAndRunAgreeTest::ProductImporter")
    @account.products.create!(sku: "A1", price_cents: 100)
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Ixport.reset_registrations!
    Ixport.reset_configuration!
    Wallflower.reset_kinds!
  end

  test "the result's added, updated and refused counts equal the preview's" do
    import = import_of("SKU,Price\nA1,150\nB2,200\nC3,lots\nD4,400\n")
    get "/data_imports/imports/#{import.id}/preview"
    preview = css_select("[data-count]").to_h { |count| [ count["data-count"], count.text.strip ] }

    post "/data_imports/imports/#{import.id}/run"
    import.reload

    assert_equal preview, { "add" => import.added_count.to_s, "update" => import.updated_count.to_s, "refused" => import.refusals.count.to_s }
  end

  private

  def import_of(csv)
    Ixport::Import.create!(key: "products", person: @person, account: @account, mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new(csv), filename: "products.csv" })
  end
end
