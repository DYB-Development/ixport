# frozen_string_literal: true

module Ixport
  class ExportTemplate < ApplicationRecord
    self.table_name = "ixport_export_templates"

    belongs_to :person, polymorphic: true
    belongs_to :account, polymorphic: true, optional: true

    def registration
      Ixport.export_registration(key)
    end

    def picked_columns
      exporter_columns = registration.exporter.constantize.columns.index_by { |column| column.key.to_s }
      columns.filter_map { |key| exporter_columns[key] }
    end
  end
end
