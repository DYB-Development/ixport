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
      import = Import.create!(key: params[:key], person: ixport_person, account: ixport_account, file: params[:file])
      redirect_to import_mapping_path(import)
    end
  end
end
