# frozen_string_literal: true

module Ixport
  class Importer
    Field = Struct.new(:key, :label, keyword_init: true)

    attr_reader :person, :account

    def initialize(person:, account:)
      @person = person
      @account = account
    end

    def self.field(key, label:)
      fields << Field.new(key: key.to_sym, label: label)
    end

    def self.fields
      @fields ||= []
    end

    def self.match_on(*keys)
      @match_fields = keys.map(&:to_sym)
    end

    def self.match_fields
      @match_fields || []
    end

    def self.match_field
      match_fields.first
    end
  end
end
