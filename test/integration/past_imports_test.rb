# frozen_string_literal: true

require "test_helper"

class PastImportsTest < ActionDispatch::IntegrationTest
  def setup
    @person = User.create!(name: "Rep")
    @account = Account.create!(name: "North")
    ApplicationController.signed_in_user = @person
    ApplicationController.signed_in_account = @account
    Ixport.register_import(:products, title: "Products", importer: "ProductImporter")
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Ixport.reset_registrations!
  end

  test "the engine's root lists the person's imports in the current account, newest first" do
    import_named("january.csv", created_at: 2.days.ago)
    import_named("march.csv", created_at: 1.hour.ago)

    get "/data_imports"

    assert_equal [ "march.csv", "january.csv" ], css_select("[data-past-import] [data-file-name]").map { |name| name.text.strip }
  end

  test "an entry shows the title, file name, status, when it was made, and its counts once it has run" do
    import = import_named("march.csv", created_at: Time.zone.local(2026, 3, 4, 9), status: "finished", added_count: 2, updated_count: 1)
    import.refusals.create!(row_number: 4, reason: "Price cents is not a number")

    get "/data_imports"

    assert_equal({ "import-title" => "Products", "file-name" => "march.csv", "status" => "Finished", "made-on" => "Mar 4, 2026", "added" => "2", "updated" => "1", "refused" => "1" }, entry_fields)
  end

  test "the imports page loads when a past import's key is no longer registered" do
    import_named("old.csv").update_columns(key: "retired_products")

    get "/data_imports"

    assert_response :success
  end

  test "the imports page leaves out a past import whose key is no longer registered" do
    import_named("current.csv")
    import_named("old.csv").update_columns(key: "retired_products")

    get "/data_imports"

    assert_equal [ "current.csv" ], css_select("[data-past-import] [data-file-name]").map { |name| name.text.strip }
  end

  test "a past import's page returns not found once its key is no longer registered" do
    import = import_named("old.csv", status: "finished")
    import.update_columns(key: "retired_products")

    get "/data_imports/imports/#{import.id}"

    assert_response :not_found
  end

  test "an entry that has not run shows no counts" do
    import_named("march.csv")

    get "/data_imports"

    assert_equal [ "import-title", "file-name", "status", "made-on" ], entry_fields.keys
  end

  test "each entry opens the page for the step the import has reached" do
    uploaded = import_named("uploaded.csv", created_at: 3.hours.ago)
    mapped = import_named("mapped.csv", created_at: 2.hours.ago, mapping: { "0" => "sku" })
    finished = import_named("finished.csv", created_at: 1.hour.ago, mapping: { "0" => "sku" }, status: "finished")

    get "/data_imports"

    assert_equal [ "/data_imports/imports/#{finished.id}", "/data_imports/imports/#{mapped.id}/preview", "/data_imports/imports/#{uploaded.id}/mapping" ],
                 css_select("[data-past-import] a[data-step-link]").map { |link| link["href"] }
  end

  test "imports made by other people, or in another account, are not listed" do
    import_named("mine.csv")
    import_named("teammate.csv", person: User.create!(name: "Teammate"))
    import_named("south.csv", account: Account.create!(name: "South"))

    get "/data_imports"

    assert_equal [ "mine.csv" ], css_select("[data-past-import] [data-file-name]").map { |name| name.text.strip }
  end

  private

  def entry_fields
    fields = %w[import-title file-name status made-on added updated refused]
    entry = css_select("[data-past-import]").first
    fields.filter_map { |field| [ field, entry.at_css("[data-#{field}]").text.strip ] if entry.at_css("[data-#{field}]") }.to_h
  end

  def import_named(filename, person: @person, account: @account, **attributes)
    Ixport::Import.create!(key: "products", person: person, account: account, file: { io: StringIO.new("SKU\nA1\n"), filename: filename }, **attributes)
  end
end
