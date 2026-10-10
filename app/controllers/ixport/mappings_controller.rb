# frozen_string_literal: true

module Ixport
  class MappingsController < ApplicationController
    def show
      @import = Import.find(params[:import_id])
      @fields = Ixport.registration(@import.key).importer.constantize.fields
    end

    def update
      import = Import.find(params[:import_id])
      import.update!(mapping: params.require(:mapping).permit(*import.headers.each_index.map(&:to_s)).to_h.compact_blank)
      head :no_content
    end
  end
end
