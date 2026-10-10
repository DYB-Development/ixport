# frozen_string_literal: true

module Ixport
  class ExportsController < ApplicationController
    def index
      @registrations = Ixport.export_registrations.values.select { |registration| allowed?(registration) }
      @templates = ExportTemplate.where(account: ixport_account).order(:name).group_by(&:key)
    end

    def show
      registration = Ixport.export_registrations[params[:id].to_sym]
      return head :not_found unless registration && allowed?(registration)

      exporter = registration.exporter.constantize.new(person: ixport_person, account: ixport_account)
      send_data CsvWriter.new(exporter).to_csv, filename: "#{registration.key}.csv", type: "text/csv"
    end
  end
end
