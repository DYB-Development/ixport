# frozen_string_literal: true

module Ixport
  class MappingsController < ApplicationController
    before_action :find_import

    def show
      @fields = Ixport.registration(@import.key).importer.constantize.fields
    end

    def update
      @import.update!(mapping: params.require(:mapping).permit(*@import.headers.each_index.map(&:to_s)).to_h.compact_blank)
      redirect_to import_preview_path(@import)
    end

    private

    def find_import
      @import = Import.find_by(id: params[:import_id], person: ixport_person)
      head :not_found unless @import
    end
  end
end
