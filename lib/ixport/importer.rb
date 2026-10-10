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
  end
end
