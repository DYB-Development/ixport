# frozen_string_literal: true

module Ixport
  class ImportsController < ApplicationController
    before_action :find_registration, only: %i[new create]
    before_action :find_import, only: :show

    def index
      @registrations = Ixport.registrations.values.select { |registration| allowed?(registration) }
      @imports = Import.where(person: ixport_person, account: ixport_account, key: @registrations.map { |registration| registration.key.to_s }).order(created_at: :desc).with_attached_file.includes(:refusals)
    end

    def new
    end

    def show
      redirect_to import_preview_path(@import) if @import.status == "pending"
    end

    def create
      import = Import.new(key: @registration.key, person: ixport_person, account: ixport_account, target: @target, file: params[:file])
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
      @target = GlobalID::Locator.locate(params[:target]) if params[:target].present?
      head :not_found unless @registration && allowed?(@registration, @target)
    end
  end
end
