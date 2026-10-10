# frozen_string_literal: true

module Ixport
  Registration = Struct.new(:key, :title, :importer, keyword_init: true)
  ExportRegistration = Struct.new(:key, :title, :exporter, keyword_init: true)

  class MissingImporter < StandardError; end

  def self.register_import(key, title:, importer:)
    registrations[key.to_sym] = Registration.new(key: key.to_sym, title: title, importer: importer.to_s)
  end

  def self.registration(key)
    registrations.fetch(key.to_sym)
  end

  def self.registrations
    @registrations ||= {}
  end

  def self.check_registrations!
    registrations.each_value do |registration|
      next if registration.importer.safe_constantize

      raise MissingImporter, "Ixport import #{registration.key} names the importer #{registration.importer}, which does not exist."
    end
  end

  def self.register_export(key, title:, exporter:)
    export_registrations[key.to_sym] = ExportRegistration.new(key: key.to_sym, title: title, exporter: exporter.to_s)
  end

  def self.export_registration(key)
    export_registrations.fetch(key.to_sym)
  end

  def self.export_registrations
    @export_registrations ||= {}
  end

  def self.reset_registrations!
    @registrations = {}
    @export_registrations = {}
  end
end
