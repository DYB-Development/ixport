# frozen_string_literal: true

module Ixport
  class MappingsController < ApplicationController
    def show
      @import = Import.find(params[:import_id])
      @fields = Ixport.registration(@import.key).importer.constantize.fields
    end
  end
end
