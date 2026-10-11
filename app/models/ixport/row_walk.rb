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
      existing = existing_records[match_key(values)]
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

    def match_fields
      @importer.class.match_fields
    end

    def match_key(values)
      return if match_fields.empty?

      key = match_fields.map { |field| cast(field, values[field]) }
      key unless key.any?(&:blank?)
    end

    def cast(field, value)
      @importer.records.klass.type_for_attribute(field.to_s).cast(value)
    end

    def existing_records
      @existing_records ||= begin
        candidates = match_fields.to_h { |field| [ field, data_rows.map { |cells| cast(field, values_of(cells)[field]) }.compact_blank ] }
        @importer.records.where(candidates).index_by { |record| match_fields.map { |field| record.public_send(field) } }
      end
    end
  end
end
