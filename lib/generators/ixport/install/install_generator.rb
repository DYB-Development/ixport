# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Ixport
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Installs Ixport: copies the migrations for its tables."

      def copy_migrations
        migration_template "create_ixport_imports.rb.erb", "db/migrate/create_ixport_imports.rb"
        migration_template "create_ixport_import_refusals.rb.erb", "db/migrate/create_ixport_import_refusals.rb"
        migration_template "create_ixport_export_templates.rb.erb", "db/migrate/create_ixport_export_templates.rb"
      end
    end
  end
end
