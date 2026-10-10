# frozen_string_literal: true

module Ixport
  class PreviewsController < ApplicationController
    before_action :find_import

    def show
      rows = RowWalk.new(@import, @import.importer_class.new(person: ixport_person, account: ixport_account)).rows
      @counts = { add: 0, update: 0, refused: 0 }.merge(rows.group_by(&:outcome).transform_values(&:size))
      @update_rows = rows.select { |row| row.outcome == :update }
    end
  end
end
