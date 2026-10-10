# frozen_string_literal: true

module Ixport
  class ExportTemplatesController < ApplicationController
    before_action :find_chosen_export

    def new
      @columns = @registration.exporter.constantize.columns
    end

    def create
      ExportTemplate.create!(key: @registration.key, name: params[:name], columns: picked_columns, person: ixport_person, account: ixport_account)
      redirect_to exports_path
    end

    private

    def find_chosen_export
      @registration = Ixport.export_registrations[params[:export_id].to_s.to_sym]
      head :not_found unless @registration&.chosen
    end

    def picked_columns
      Array(params[:columns]).compact_blank & @registration.exporter.constantize.columns.map { |column| column.key.to_s }
    end
  end
end
