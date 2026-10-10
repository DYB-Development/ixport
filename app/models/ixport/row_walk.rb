# frozen_string_literal: true

require "csv"

module Ixport
  class RowWalk
    Row = Struct.new(:number, :record, :outcome, :reason, keyword_init: true)

    def initialize(import, importer)
      @import = import
      @importer = importer
    end

    def rows
      @rows ||= data_rows.each_with_index.map { |cells, index| row_for(cells, index + 2) }
    end

    private

    def row_for(cells, number)
      values = values_of(cells)
      existing = existing_records[values[match_field]]
      record = existing ? existing.tap { |found| found.assign_attributes(values) } : @importer.records.new(values)
      return Row.new(number: number, record: record, outcome: :refused, reason: record.errors.full_messages.to_sentence) unless record.valid?

      Row.new(number: number, record: record, outcome: existing ? :update : :add)
    end

    def data_rows
      @data_rows ||= CSV.parse(@import.contents).drop(1)
    end

    def values_of(cells)
      @import.mapping.to_h { |column, field| [ field.to_sym, cells[column.to_i] ] }
    end

    def match_field
      @importer.class.match_field
    end

    def existing_records
      @existing_records ||= begin
        match_values = data_rows.map { |cells| values_of(cells)[match_field] }.compact_blank
        @importer.records.where(match_field => match_values).index_by { |record| record.public_send(match_field).to_s }
      end
    end
  end
end
