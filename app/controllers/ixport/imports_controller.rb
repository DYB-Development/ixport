# frozen_string_literal: true

module Ixport
  class ImportsController < ApplicationController
    def index
      @registrations = Ixport.registrations.values
    end
  end
end
