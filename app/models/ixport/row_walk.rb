# frozen_string_literal: true

require "csv"

module Ixport
  class RowWalk
    Row = Struct.new(:number, :record, :outcome, keyword_init: true)

    def initialize(import, importer)
      @import = import
      @importer = importer
    end

    def rows
      @rows ||= data_rows.each_with_index.map do |cells, index|
        values = values_of(cells)
        existing = existing_records[values[match_field]]
        if existing
          existing.assign_attributes(values)
          Row.new(number: index + 2, record: existing, outcome: :update)
        else
          Row.new(number: index + 2, record: @importer.records.new(values), outcome: :add)
        end
      end
    end

    private

    def data_rows
      @data_rows ||= CSV.parse(@import.file.download).drop(1)
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
