# frozen_string_literal: true

module Ixport
  module AccessRule
    def allows?(person, account)
      allow.nil? || allow.call(person, account)
    end
  end

  Registration = Struct.new(:key, :title, :importer, :allow, keyword_init: true) { include AccessRule }
  ExportRegistration = Struct.new(:key, :title, :exporter, :chosen, :allow, keyword_init: true) { include AccessRule }

  class MissingImporter < StandardError; end
  class MissingExporter < StandardError; end

  def self.register_import(key, title:, importer:, allow: nil)
    registrations[key.to_sym] = Registration.new(key: key.to_sym, title: title, importer: importer.to_s, allow: allow)
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
    export_registrations.each_value do |registration|
      next if registration.exporter.safe_constantize

      raise MissingExporter, "Ixport export #{registration.key} names the exporter #{registration.exporter}, which does not exist."
    end
  end

  def self.register_export(key, title:, exporter:, chosen: false, allow: nil)
    export_registrations[key.to_sym] = ExportRegistration.new(key: key.to_sym, title: title, exporter: exporter.to_s, chosen: chosen, allow: allow)
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
