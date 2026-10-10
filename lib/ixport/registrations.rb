# frozen_string_literal: true

module Ixport
  Registration = Struct.new(:key, :title, :importer, keyword_init: true)

  def self.register_import(key, title:, importer:)
    registrations[key.to_sym] = Registration.new(key: key.to_sym, title: title, importer: importer.to_s)
  end

  def self.registration(key)
    registrations.fetch(key.to_sym)
  end

  def self.registrations
    @registrations ||= {}
  end

  def self.reset_registrations!
    @registrations = {}
  end
end
