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
end

ActiveRecord::Migration.verbose = false
require Gem.loaded_specs["activestorage"].full_gem_path + "/db/migrate/20170806125915_create_active_storage_tables"
CreateActiveStorageTables.migrate(:up)
[ "create_ixport_imports" ].each do |name|
  template = File.expand_path("../lib/generators/ixport/install/templates/#{name}.rb.erb", __dir__)
  eval(ERB.new(File.read(template)).result) # rubocop:disable Security/Eval
  name.camelize.constantize.migrate(:up)
end

Rails.application.config.action_dispatch.show_exceptions = :none

ActionDispatch::IntegrationTest.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
ActionDispatch::IntegrationTest.file_fixture_path = File.expand_path("fixtures/files", __dir__)
