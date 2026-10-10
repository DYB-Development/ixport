# frozen_string_literal: true

require "csv"

module Ixport
  class CsvWriter
    def initialize(exporter, columns = exporter.class.columns)
      @exporter = exporter
      @columns = columns
    end

    def to_csv
      CSV.generate do |csv|
        csv << @columns.map(&:label)
        @exporter.records.each { |record| csv << @columns.map { |column| @exporter.value(record, column) } }
      end
    end
  end
end
