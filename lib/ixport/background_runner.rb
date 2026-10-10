# frozen_string_literal: true

module Ixport
  def self.background_runner
    case configuration.background_runner
    when nil then nil
    when :wallflower then WallflowerRunner
    else configuration.background_runner.to_s.constantize
    end
  end

  def self.run_import(import, reporter: NullReporter.new)
    import.run!(import.importer_class.new(person: import.person, account: import.account), reporter: reporter)
  end

  def self.install_background_runner!
    return unless configuration.background_runner == :wallflower

    Wallflower.register_kind(:ixport_import, title: "Import", runner: "Ixport::WallflowerTaskRunner")
  end
end
