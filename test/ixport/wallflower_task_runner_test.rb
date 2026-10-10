# frozen_string_literal: true

require "test_helper"

class Ixport::WallflowerTaskRunnerTest < ActiveSupport::TestCase
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
    match_on :sku

    def records
      account.products
    end
  end

  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
    Ixport.register_import(:products, title: "Products", importer: "Ixport::WallflowerTaskRunnerTest::ProductImporter")
    Wallflower.register_kind(:ixport_import, title: "Import", runner: "Ixport::WallflowerTaskRunner")
    @account.products.create!(sku: "A1", price_cents: 100)
    csv = "SKU,Price\nA1,150\nB2,200\nC3,lots\n"
    @import = Ixport::Import.create!(key: "products", person: @person, account: @account, status: "running", mapping: { "0" => "sku", "1" => "price_cents" }, file: { io: StringIO.new(csv), filename: "products.csv" })
    @task = Wallflower::Task.create!(kind: "ixport_import", person: @person, account: @account, params: { "import_id" => @import.id })
  end

  def teardown
    Ixport.reset_registrations!
    Wallflower.reset_kinds!
  end

  test "the task reports the import's progress and, when it finishes, the rows changed and refused" do
    Wallflower::RunJob.perform_now(@task)

    assert_equal [ 3, 3, 2, 1 ], @task.reload.then { |task| [ task.total, task.done, task.changed_count, task.refusals.size ] }
  end

  test "the finished task links to the import's result page" do
    Wallflower::RunJob.perform_now(@task)

    assert_equal "/data_imports/imports/#{@import.id}", @task.reload.result_url
  end
end
