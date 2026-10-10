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
        Row.new(number: index + 2, record: @importer.records.new(values_of(cells)), outcome: :add)
      end
    end

    private

    def data_rows
      CSV.parse(@import.file.download).drop(1)
    end

    def values_of(cells)
      @import.mapping.to_h { |column, field| [ field.to_sym, cells[column.to_i] ] }
    end
  end
end
