# frozen_string_literal: true

module Ixport
  class WallflowerRunner
    def self.enqueue(import)
      task = Wallflower.start(kind: :ixport_import, person: import.person, account: import.account, params: { "import_id" => import.id })
      import.update!(wallflower_task_id: task.id)
    end
  end
end
