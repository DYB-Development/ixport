# frozen_string_literal: true

module Ixport
  class ApplicationController < ::ApplicationController
    before_action { send(Ixport.configuration.authentication_method) }
    layout -> { Ixport.configuration.layout }
  end
end
