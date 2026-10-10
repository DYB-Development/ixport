# frozen_string_literal: true

module Ixport
  class ImportsController < ApplicationController
    def index
      @registrations = Ixport.registrations.values
    end

    def new
      @registration = Ixport.registration(params[:key])
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
  end
end
