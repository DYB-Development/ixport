# frozen_string_literal: true

module Ixport
  class WallflowerTaskRunner
    def call(task)
      import = Import.find(task.params["import_id"])
      import.run!(import.importer_class.new(person: import.person, account: import.account), reporter: task)
    end
  end
end
