# frozen_string_literal: true

module Ixport
  class RunsController < ApplicationController
    before_action :find_import

    def create
      @import.run!(@import.importer_class.new(person: ixport_person, account: ixport_account))
      head :no_content
    end
  end
end
