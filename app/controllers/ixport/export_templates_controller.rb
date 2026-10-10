# frozen_string_literal: true

module Ixport
  class ExportTemplatesController < ApplicationController
    before_action :find_chosen_export, only: %i[new create]
    before_action :find_template, only: %i[show update destroy]

    def new
      @columns = @registration.exporter.constantize.columns
    end

    def create
      ExportTemplate.create!(key: @registration.key, name: params[:name], columns: known_columns(@registration), person: ixport_person, account: ixport_account)
      redirect_to exports_path
    end

    def show
      exporter = @template.registration.exporter.constantize.new(person: ixport_person, account: ixport_account)
      send_data CsvWriter.new(exporter, @template.picked_columns).to_csv, filename: "#{@template.name.parameterize}.csv", type: "text/csv"
    end

    def update
      @template.update!(name: params[:name], columns: known_columns(@template.registration))
      redirect_to exports_path
    end

    def destroy
      @template.destroy!
      redirect_to exports_path
    end

    private

    def find_template
      @template = ExportTemplate.find_by(id: params[:id], account: ixport_account)
      head :not_found unless @template
    end

    def find_chosen_export
      @registration = Ixport.export_registrations[params[:export_id].to_s.to_sym]
      head :not_found unless @registration&.chosen
    end

    def known_columns(registration)
      Array(params[:columns]).compact_blank & registration.exporter.constantize.columns.map { |column| column.key.to_s }
    end
  end
end
