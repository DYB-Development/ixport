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

  private

  def import_named(filename, person: @person, account: @account, **attributes)
    Ixport::Import.create!(key: "products", person: person, account: account, file: { io: StringIO.new("SKU\nA1\n"), filename: filename }, **attributes)
  end
end
