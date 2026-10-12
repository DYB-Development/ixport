# frozen_string_literal: true

module Ixport
  class WallflowerTaskRunner
    include Rails.application.routes.mounted_helpers

    def call(task)
      import = Import.find(task.params["import_id"])
      import.run!(reporter: task, report_failure: false)
      task.link_result(ixport.import_path(import))
      raise(import.run_error || ImportFailed.new(import.error_message)) if import.failed?
    end
  end
end
