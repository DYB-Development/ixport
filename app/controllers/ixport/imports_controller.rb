# frozen_string_literal: true

module Ixport
  class ImportsController < ApplicationController
    before_action :find_registration, only: :new

    def index
      @registrations = Ixport.registrations.values
    end

    def new
    end

    def create
      import = Import.new(key: params[:key], person: ixport_person, account: ixport_account, file: params[:file])
      if import.save
        redirect_to import_mapping_path(import)
      else
        @registration = Ixport.registration(params[:key])
        @error = import.errors[:file].first
        render :new, status: :unprocessable_entity
      end
    end

    private

    def find_registration
      @registration = Ixport.registrations[params[:key].to_s.to_sym]
      head :not_found unless @registration
    end
  end
end
