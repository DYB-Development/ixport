# frozen_string_literal: true

require "csv"

module Ixport
  class Import < ApplicationRecord
    self.table_name = "ixport_imports"

    belongs_to :person, polymorphic: true
    belongs_to :account, polymorphic: true, optional: true

    has_one_attached :file

    validate :file_has_header_row, on: :create

    def headers
      CSV.parse_line(file.download) || []
    end

    private

    def file_has_header_row
      errors.add(:file, "This file has no header row.") if CSV.parse_line(incoming_file_contents).blank?
    end

    def incoming_file_contents
      attachable = attachment_changes["file"]&.attachable
      io = attachable.is_a?(Hash) ? attachable[:io] : attachable
      return "" unless io

      io.read.tap { io.rewind }.to_s
    end
  end
end
