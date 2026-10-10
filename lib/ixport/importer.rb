# frozen_string_literal: true

module Ixport
  class Importer
    Field = Struct.new(:key, :label, keyword_init: true)

    def self.field(key, label:)
      fields << Field.new(key: key.to_sym, label: label)
    end

    def self.fields
      @fields ||= []
    end

    def self.match_on(key)
      @match_field = key.to_sym
    end

    def self.match_field
      @match_field
    end
  end
end
