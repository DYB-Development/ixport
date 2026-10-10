# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Ixport
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Installs Ixport: copies the migrations for its tables."

      def copy_migration
        migration_template "create_ixport_imports.rb.erb", "db/migrate/create_ixport_imports.rb"
      end
    end
  end
end
