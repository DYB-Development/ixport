# frozen_string_literal: true

module Ixport
  class ApplicationController < ::ApplicationController
    layout -> { Ixport.configuration.layout }
  end
end
