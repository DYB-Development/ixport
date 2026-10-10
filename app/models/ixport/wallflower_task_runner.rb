# frozen_string_literal: true

module Ixport
  class WallflowerTaskRunner
    include Rails.application.routes.mounted_helpers

    def call(task)
      import = Import.find(task.params["import_id"])
      Ixport.run_import(import, reporter: task)
      task.link_result(ixport.import_path(import))
    end
  end
end
