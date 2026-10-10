# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "generators/ixport/install/install_generator"

class Ixport::Generators::InstallGeneratorTest < ActiveSupport::TestCase
  def destination
    @destination ||= File.expand_path("../../tmp/install_generator_test", __dir__)
  end

  def setup
    FileUtils.mkdir_p(destination)
    Rails::Generators.invoke("ixport:install", [], destination_root: destination, quiet: true)
  end

  def teardown
    FileUtils.rm_rf(destination)
  end

  test "copies a migration that creates the imports table" do
    assert_includes migration, "create_table :ixport_imports"
  end

  test "the migration gives each import the person who started it" do
    assert_includes migration, "t.references :person, polymorphic: true, null: false"
  end

  test "the migration lets an import belong to an account" do
    assert_includes migration, "t.references :account, polymorphic: true, null: true"
  end

  test "the migration records which registered import each import is for" do
    assert_includes migration, "t.string :key, null: false"
  end

  test "the migration stores which field each of the file's columns maps to" do
    assert_includes migration, "t.json :mapping"
  end

  private

  def migration
    File.read(Dir.glob("#{destination}/db/migrate/*_create_ixport_imports.rb").first.to_s)
  end
end
