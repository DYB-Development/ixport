# frozen_string_literal: true

module Ixport
  def self.install_background_runner!
    return unless configuration.background_runner == :wallflower

    Wallflower.register_kind(:ixport_import, title: "Import", runner: "Ixport::WallflowerTaskRunner")
  end
end
