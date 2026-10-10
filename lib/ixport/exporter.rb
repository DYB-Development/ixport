# frozen_string_literal: true

module Ixport
  class Exporter
    Column = Struct.new(:key, :label, keyword_init: true)

    def self.column(key, label:)
      columns << Column.new(key: key.to_sym, label: label)
    end

    def self.columns
      @columns ||= []
    end
  end
end
