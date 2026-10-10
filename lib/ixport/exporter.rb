# frozen_string_literal: true

module Ixport
  class Exporter
    Column = Struct.new(:key, :label, keyword_init: true)

    attr_reader :person, :account

    def initialize(person:, account:)
      @person = person
      @account = account
    end

    def self.column(key, label:)
      columns << Column.new(key: key.to_sym, label: label)
    end

    def self.columns
      @columns ||= []
    end

    def value(record, column)
      record.public_send(column.key)
    end
  end
end
