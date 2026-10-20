# frozen_string_literal: true

module Ixport
  class PreviewsController < ApplicationController
    before_action :find_import

    def show
      return redirect_to import_path(@import) unless @import.status == "pending"

      rows = @import.rows
      @counts = { add: 0, update: 0, refused: 0 }.merge(rows.group_by(&:outcome).transform_values(&:size))
      @update_rows = rows.select { |row| row.outcome == :update }
      @refused_rows = rows.select { |row| row.outcome == :refused }
      @whole_file_refused = @import.whole_file_refused?(rows)
    end
  end
end
