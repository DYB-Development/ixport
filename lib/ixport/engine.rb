# frozen_string_literal: true

module Ixport
  class Engine < ::Rails::Engine
    isolate_namespace Ixport

    config.after_initialize do
      Ixport.check_registrations!
      Ixport.install_background_runner!
    end
  end
end
