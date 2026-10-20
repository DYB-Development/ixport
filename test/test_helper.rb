# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
  end

  create_table :accounts, force: true do |t|
    t.string :name
  end

  create_table :products, force: true do |t|
    t.references :account
    t.string :sku
    t.integer :price_cents
  end
end

ActiveRecord::Migration.verbose = false
require Gem.loaded_specs["activestorage"].full_gem_path + "/db/migrate/20170806125915_create_active_storage_tables"
CreateActiveStorageTables.migrate(:up)
[ "create_ixport_imports", "create_ixport_import_refusals", "create_ixport_export_templates", "add_wallflower_task_to_ixport_imports", "add_error_message_to_ixport_imports", "add_target_to_ixport_imports" ].each do |name|
  template = File.expand_path("../lib/generators/ixport/install/templates/#{name}.rb.erb", __dir__)
  eval(ERB.new(File.read(template)).result) # rubocop:disable Security/Eval
  name.camelize.constantize.migrate(:up)
end

wallflower_templates = File.join(Gem.loaded_specs["wallflower"].full_gem_path, "lib/generators/wallflower/install/templates")
[ "create_wallflower_tasks", "create_wallflower_refusals", "add_result_url_to_wallflower_tasks", "add_error_message_to_wallflower_tasks", "add_started_at_to_wallflower_tasks" ].each do |name|
  eval(ERB.new(File.read("#{wallflower_templates}/#{name}.rb.erb")).result) # rubocop:disable Security/Eval
  name.camelize.constantize.migrate(:up)
end

Rails.application.config.action_dispatch.show_exceptions = :none

ActionDispatch::IntegrationTest.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
ActionDispatch::IntegrationTest.file_fixture_path = File.expand_path("fixtures/files", __dir__)
