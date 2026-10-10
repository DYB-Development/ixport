# frozen_string_literal: true

module Ixport
  class MappingsController < ApplicationController
    before_action :find_import

    def show
      @fields = @import.importer_class.fields
    end

    def update
      @import.update!(mapping: params.require(:mapping).permit(*@import.headers.each_index.map(&:to_s)).to_h.compact_blank)
      redirect_to import_preview_path(@import)
    end
  end
end
