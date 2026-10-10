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
