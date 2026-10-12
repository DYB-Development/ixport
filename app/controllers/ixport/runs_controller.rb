# frozen_string_literal: true

module Ixport
  class RunsController < ApplicationController
    before_action :find_import

    def create
      runner = Ixport.background_runner
      return run_in_request unless runner
      return redirect_to import_path(@import) unless @import.status == "pending"

      @import.update!(status: "running")
      hand_over(runner)
    end

    private

    def hand_over(runner)
      runner.enqueue(@import)
      redirect_to @import.wallflower_task_id ? wallflower.task_path(@import.wallflower_task_id) : import_path(@import)
    rescue StandardError => error
      Rails.error.report(error)
      @import.update!(status: "pending")
      redirect_to import_preview_path(@import)
    end

    def run_in_request
      @import.run!
      redirect_to import_path(@import)
    end
  end
end
