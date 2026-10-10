# frozen_string_literal: true

require "csv"

module Ixport
  class Import < ApplicationRecord
    self.table_name = "ixport_imports"

    belongs_to :person, polymorphic: true
    belongs_to :account, polymorphic: true, optional: true

    has_one_attached :file

    def headers
      CSV.parse_line(file.download) || []
    end
  end
end
