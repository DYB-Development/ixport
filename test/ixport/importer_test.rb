# frozen_string_literal: true

require "test_helper"

class Ixport::ImporterTest < ActiveSupport::TestCase
  class ProductImporter < Ixport::Importer
    field :sku, label: "SKU"
    field :price_cents, label: "Price"
    match_on :sku
  end

  test "an importer lists its fields with the labels a person sees" do
    assert_equal [ [ :sku, "SKU" ], [ :price_cents, "Price" ] ], ProductImporter.fields.map { |field| [ field.key, field.label ] }
  end

  test "an importer declares the one field rows are matched on" do
    assert_equal :sku, ProductImporter.match_field
  end

  test "an importer knows the person and account an import is for" do
    person = User.create!(name: "Rep")
    account = Account.create!(name: "North")

    assert_equal [ person, account ], ProductImporter.new(person: person, account: account).then { |importer| [ importer.person, importer.account ] }
  end
end
