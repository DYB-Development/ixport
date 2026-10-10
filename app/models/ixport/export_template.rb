# frozen_string_literal: true

module Ixport
  class ExportTemplate < ApplicationRecord
    self.table_name = "ixport_export_templates"

    belongs_to :person, polymorphic: true
    belongs_to :account, polymorphic: true, optional: true
  end
end
