# frozen_string_literal: true

module Ixport
  class RunsController < ApplicationController
    before_action :find_import

    def create
      @import.run!(@import.importer_class.new(person: ixport_person, account: ixport_account))
      redirect_to import_path(@import)
    end
  end
end
