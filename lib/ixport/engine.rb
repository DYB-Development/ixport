# frozen_string_literal: true

module Ixport
  class Engine < ::Rails::Engine
    isolate_namespace Ixport

    config.after_initialize { Ixport.check_registrations! }
  end
end
