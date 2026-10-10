# frozen_string_literal: true

module Ixport
  class ImportsController < ApplicationController
    before_action :find_registration, only: %i[new create]
    before_action :find_import, only: :show

    def index
      @registrations = Ixport.registrations.values
      @imports = Import.where(person: ixport_person, account: ixport_account).order(created_at: :desc).with_attached_file.includes(:refusals)
    end

    def new
    end

    def show
      redirect_to import_preview_path(@import) unless @import.finished? || @import.running?
    end

    def create
      import = Import.new(key: @registration.key, person: ixport_person, account: ixport_account, file: params[:file])
      if import.save
        redirect_to import_mapping_path(import)
      else
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
