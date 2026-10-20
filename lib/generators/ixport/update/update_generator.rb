# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Ixport
  module Generators
    class UpdateGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("../install/templates", __dir__)

      desc "Updates Ixport: copies the migrations added since it was installed."

      def copy_export_templates_migration
        migration_template "create_ixport_export_templates.rb.erb", "db/migrate/create_ixport_export_templates.rb"
      end

      def copy_wallflower_task_migration
        migration_template "add_wallflower_task_to_ixport_imports.rb.erb", "db/migrate/add_wallflower_task_to_ixport_imports.rb"
      end

      def copy_error_message_migration
        migration_template "add_error_message_to_ixport_imports.rb.erb", "db/migrate/add_error_message_to_ixport_imports.rb"
      end

      def copy_target_migration
        migration_template "add_target_to_ixport_imports.rb.erb", "db/migrate/add_target_to_ixport_imports.rb"
      end
    end
  end
end
