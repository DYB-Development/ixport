# frozen_string_literal: true

module Ixport
  class ImportsController < ApplicationController
    def index
      @registrations = Ixport.registrations.values
    end

    def create
      Import.create!(key: params[:key], person: ixport_person, account: ixport_account, file: params[:file])
      head :created
    end
  end
end
