# frozen_string_literal: true

require "csv"

module Ixport
  class Import < ApplicationRecord
    self.table_name = "ixport_imports"

    belongs_to :person, polymorphic: true
    belongs_to :account, polymorphic: true, optional: true
    belongs_to :target, polymorphic: true, optional: true

    has_one_attached :file
    has_many :refusals, -> { order(:row_number) }, class_name: "Ixport::ImportRefusal", dependent: :destroy

    STALLED_AFTER = 1.hour

    validate :incoming_file_is_usable, on: :create

    attr_reader :run_error

    def run!(reporter: NullReporter.new, report_failure: true)
      with_lock do
        walk_and_save(reporter, report_failure) if status.in?(%w[pending running])
      end
    end

    def finished?
      status == "finished"
    end

    def running?
      status == "running"
    end

    def stalled?
      running? && updated_at < STALLED_AFTER.ago
    end

    def failed?
      status == "failed"
    end

    def step
      return :result if finished?

      mapping.present? ? :preview : :mapping
    end

    def title
      Ixport.registration(key).title
    end

    def rows
      RowWalk.new(self, importer).rows
    end

    def whole_file_refused?(rows = self.rows)
      Ixport.registration(key).refuse_whole_file && rows.any? { |row| row.outcome == :refused }
    end

    def importer
      importer_class.new(person: person, account: account, target: target)
    end

    def importer_class
      Ixport.registration(key).importer.constantize
    end

    def row_count
      [ CSV.parse(contents).size - 1, 0 ].max
    end

    def headers
      CSV.parse_line(contents) || []
    end

    def contents
      self.class.readable(file.download)
    end

    def self.readable(text)
      text.to_s.dup.force_encoding(Encoding::UTF_8).delete_prefix("\uFEFF")
    end

    private

    def walk_and_save(reporter, report_failure)
      counts = { add: 0, update: 0 }
      rows = self.rows
      saving = !whole_file_refused?(rows)
      reporter.set_total(rows.size)
      rows.each do |row|
        save_row(row, reporter, saving)
        counts[row.outcome] += 1 if saving && counts.key?(row.outcome)
        reporter.advance
      end
      update!(status: "finished", added_count: counts[:add], updated_count: counts[:update])
    rescue StandardError => error
      @run_error = error
      Rails.error.report(error) if report_failure
      update!(status: "failed", error_message: error.message, added_count: counts[:add], updated_count: counts[:update])
    end

    def save_row(row, reporter, saving)
      if row.outcome == :refused
        refusals.create!(row_number: row.number, reason: row.reason)
        reporter.refuse(label: "Row #{row.number}", reason: row.reason)
      elsif saving
        self.class.transaction(requires_new: true) { row.record.save! }
      end
    end

    def incoming_file_is_usable
      text = incoming_file_contents
      return errors.add(:file, "This file is not UTF-8 text. Save it as UTF-8 and upload it again.") unless text.valid_encoding?

      rows = CSV.parse(text)
      return errors.add(:file, "This file has no header row.") if rows.first.blank?

      check_inline_row_limit(rows.size - 1) unless Ixport.configuration.background_runner
    rescue CSV::MalformedCSVError => error
      errors.add(:file, "This file could not be read past line #{error.line_number}. Check the quotes on that line.")
    end

    def check_inline_row_limit(row_count)
      limit = Ixport.configuration.inline_row_limit
      errors.add(:file, "This file has #{row_count} rows, and the most an import can have is #{limit}.") if row_count > limit
    end

    def incoming_file_contents
      attachable = attachment_changes["file"]&.attachable
      io = attachable.is_a?(Hash) ? attachable[:io] : attachable
      return "" unless io

      self.class.readable(io.read.tap { io.rewind })
    end
  end
end
