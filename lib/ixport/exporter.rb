# frozen_string_literal: true

module Ixport
  class Exporter
    Column = Struct.new(:key, :label, :through, keyword_init: true)

    attr_reader :person, :account

    def initialize(person:, account:)
      @person = person
      @account = account
    end

    def self.column(key, label:, through: nil)
      columns << Column.new(key: key.to_sym, label: label, through: through)
    end

    def self.columns
      @columns ||= []
    end

    def value(record, column)
      source = column.through ? record.public_send(column.through) : record
      source&.public_send(column.key)
    end
  end
end
