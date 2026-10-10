# frozen_string_literal: true

require "csv"

module Ixport
  class CsvWriter
    def initialize(exporter)
      @exporter = exporter
    end

    def to_csv
      columns = @exporter.class.columns
      CSV.generate do |csv|
        csv << columns.map(&:label)
        @exporter.records.each { |record| csv << columns.map { |column| @exporter.value(record, column) } }
      end
    end
  end
end
