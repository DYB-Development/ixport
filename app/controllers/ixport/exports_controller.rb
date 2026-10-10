# frozen_string_literal: true

module Ixport
  class ExportsController < ApplicationController
    def index
      @registrations = Ixport.export_registrations.values
    end
  end
end
