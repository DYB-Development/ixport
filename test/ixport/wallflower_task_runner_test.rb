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

  test "the task and the import list the same refused rows with the same reasons" do
    Wallflower::RunJob.perform_now(@task)

    assert_equal @import.refusals.map { |refusal| [ "Row #{refusal.row_number}", refusal.reason ] }, @task.reload.refusals.map { |refusal| [ refusal.label, refusal.reason ] }
  end

  test "when the import fails, its wallflower task fails with the same message and still links to the import's page" do
    @import.update!(file: { io: StringIO.new("SKU,Price\nRAISE,1\n"), filename: "products.csv" })

    Wallflower::RunJob.perform_now(@task)

    assert_equal [ "failed", "Disk full", "/data_imports/imports/#{@import.id}" ], [ @task.reload.status, @task.error_message, @task.result_url ]
  end

  test "an import that fails while wallflower runs it gives one entry in the host's error reporting" do
    @import.update!(file: { io: StringIO.new("SKU,Price\nRAISE,1\n"), filename: "products.csv" })

    reports = capture_error_reports { Wallflower::RunJob.perform_now(@task) }

    assert_equal 1, reports.size
  end

  test "the one entry for an import that fails while wallflower runs it carries the error the import raised" do
    @import.update!(file: { io: StringIO.new("SKU,Price\nRAISE,1\n"), filename: "products.csv" })

    reports = capture_error_reports { Wallflower::RunJob.perform_now(@task) }

    assert_equal [ [ RuntimeError, "Disk full" ] ], reports.map { |report| [ report.error.class, report.error.message ] }
  end

  test "a task run for an import that had already failed fails with the import's message" do
    @import.update!(status: "failed", error_message: "Disk full")

    Wallflower::RunJob.perform_now(@task)

    assert_equal [ "failed", "Disk full" ], [ @task.reload.status, @task.error_message ]
  end

  test "an import that fails while wallflower runs it is marked failed" do
    @import.update!(file: { io: StringIO.new("SKU,Price\nRAISE,1\n"), filename: "products.csv" })

    Wallflower::RunJob.perform_now(@task)

    assert_predicate @import.reload, :failed?
  end
end
