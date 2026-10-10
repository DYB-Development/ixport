# frozen_string_literal: true

module Ixport
  class RunsController < ApplicationController
    before_action :find_import

    def create
      runner = Ixport.background_runner
      return run_in_request unless runner

      @import.update!(status: "running")
      runner.enqueue(@import)
      redirect_to @import.wallflower_task_id ? wallflower.task_path(@import.wallflower_task_id) : import_path(@import)
    end

    private

    def run_in_request
      @import.run!(@import.importer_class.new(person: ixport_person, account: ixport_account))
      redirect_to import_path(@import)
    end
  end
end
