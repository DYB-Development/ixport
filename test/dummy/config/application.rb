# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "active_job/railtie"
require "active_storage/engine"
require "action_cable/engine"

Bundler.require(*Rails.groups)
require "wallflower"
require "ixport"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = true
    config.root = File.expand_path("..", __dir__)
  end
end
