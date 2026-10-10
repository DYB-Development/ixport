# frozen_string_literal: true

require "csv"

module Ixport
  class Import < ApplicationRecord
    self.table_name = "ixport_imports"

    belongs_to :person, polymorphic: true
    belongs_to :account, polymorphic: true, optional: true

    has_one_attached :file
    has_many :refusals, -> { order(:row_number) }, class_name: "Ixport::ImportRefusal", dependent: :destroy

    validate :file_has_header_row, on: :create
    validate :file_within_inline_row_limit, on: :create, unless: -> { Ixport.configuration.background_runner }

    def run!(importer, reporter: NullReporter.new)
      with_lock do
        walk_and_save(importer, reporter) unless finished?
      end
    end

    def finished?
      status == "finished"
    end

    def step
      return :result if finished?

      mapping.present? ? :preview : :mapping
    end

    def title
      Ixport.registration(key).title
    end

    def importer_class
      Ixport.registration(key).importer.constantize
    end

    def headers
      CSV.parse_line(file.download) || []
    end

    private

    def walk_and_save(importer, reporter)
      rows = RowWalk.new(self, importer).rows
      reporter.set_total(rows.size)
      rows.each do |row|
        if row.outcome == :refused
          refusals.create!(row_number: row.number, reason: row.reason)
          reporter.refuse(label: "Row #{row.number}", reason: row.reason)
        else
          row.record.save!
        end
        reporter.advance
      end
      update!(status: "finished", added_count: rows.count { |row| row.outcome == :add }, updated_count: rows.count { |row| row.outcome == :update })
    end

    def file_has_header_row
      errors.add(:file, "This file has no header row.") if CSV.parse_line(incoming_file_contents).blank?
    end

    def file_within_inline_row_limit
      limit = Ixport.configuration.inline_row_limit
      rows = [ CSV.parse(incoming_file_contents).size - 1, 0 ].max
      errors.add(:file, "This file has #{rows} rows, and the most an import can have is #{limit}.") if rows > limit
    end

    def incoming_file_contents
      attachable = attachment_changes["file"]&.attachable
      io = attachable.is_a?(Hash) ? attachable[:io] : attachable
      return "" unless io

      io.read.tap { io.rewind }.to_s
    end
  end
end
