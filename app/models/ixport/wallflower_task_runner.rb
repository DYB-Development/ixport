# frozen_string_literal: true

module Ixport
  class WallflowerTaskRunner
    include Rails.application.routes.mounted_helpers

    def call(task)
      import = Import.find(task.params["import_id"])
      import.run!(import.importer_class.new(person: import.person, account: import.account), reporter: task)
      task.link_result(ixport.import_path(import))
    end
  end
end
