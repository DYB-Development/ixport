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

  test "the migration records whether an import has run" do
    assert_includes migration, "t.string :status, null: false, default: \"pending\""
  end

  test "the migration counts the rows an import added" do
    assert_includes migration, "t.integer :added_count, null: false, default: 0"
  end

  test "the migration counts the rows an import updated" do
    assert_includes migration, "t.integer :updated_count, null: false, default: 0"
  end

  test "copies a migration that creates the table of rows an import refused" do
    assert_includes refusals_migration, "create_table :ixport_import_refusals"
  end

  test "copies a migration that creates the export templates table" do
    assert_equal 1, Dir.glob("#{destination}/db/migrate/*_create_ixport_export_templates.rb").size
  end

  test "copies a migration that links an import to the wallflower task that runs it" do
    assert_equal 1, Dir.glob("#{destination}/db/migrate/*_add_wallflower_task_to_ixport_imports.rb").size
  end

  test "copies a migration that keeps the error a failed import stopped on" do
    assert_equal 1, Dir.glob("#{destination}/db/migrate/*_add_error_message_to_ixport_imports.rb").size
  end

  test "copies a migration that lets an import name the record its rows are added to" do
    assert_includes File.read(Dir.glob("#{destination}/db/migrate/*_add_target_to_ixport_imports.rb").first.to_s), "add_reference :ixport_imports, :target, polymorphic: true, null: true"
  end

  private

  def refusals_migration
    File.read(Dir.glob("#{destination}/db/migrate/*_create_ixport_import_refusals.rb").first.to_s)
  end

  def migration
    File.read(Dir.glob("#{destination}/db/migrate/*_create_ixport_imports.rb").first.to_s)
  end
end
