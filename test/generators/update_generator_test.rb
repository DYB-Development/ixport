# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "generators/ixport/update/update_generator"

class Ixport::Generators::UpdateGeneratorTest < ActiveSupport::TestCase
  def destination
    @destination ||= File.expand_path("../../tmp/update_generator_test", __dir__)
  end

  def setup
    FileUtils.mkdir_p("#{destination}/db/migrate")
    File.write("#{destination}/db/migrate/20261010000000_create_ixport_imports.rb", "")
    File.write("#{destination}/db/migrate/20261010000001_create_ixport_import_refusals.rb", "")
  end

  def teardown
    FileUtils.rm_rf(destination)
  end

  test "adds the export templates table to an app that installed earlier" do
    update

    assert_equal 1, migrations_named("create_ixport_export_templates").size
  end

  test "adds the link to the wallflower task to an app that installed earlier" do
    update

    assert_equal 1, migrations_named("add_wallflower_task_to_ixport_imports").size
  end

  test "adds the error a failed import stopped on to an app that installed earlier" do
    update

    assert_equal 1, migrations_named("add_error_message_to_ixport_imports").size
  end

  test "adds the record an import's rows are added to, to an app that installed earlier" do
    update

    assert_equal 1, migrations_named("add_target_to_ixport_imports").size
  end

  private

  def update
    Rails::Generators.invoke("ixport:update", [], destination_root: destination, quiet: true)
  end

  def migrations_named(name)
    Dir.glob("#{destination}/db/migrate/*_#{name}.rb")
  end
end
