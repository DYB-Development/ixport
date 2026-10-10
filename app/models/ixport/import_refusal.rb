# frozen_string_literal: true

module Ixport
  class ImportRefusal < ApplicationRecord
    self.table_name = "ixport_import_refusals"

    belongs_to :import
  end
end
