# frozen_string_literal: true

module Ixport
  class ApplicationController < ::ApplicationController
    before_action { send(Ixport.configuration.authentication_method) }
    layout -> { Ixport.configuration.layout }

    private

    def ixport_person
      send(Ixport.configuration.current_person_method)
    end

    def ixport_account
      send(Ixport.configuration.current_account_method)
    end
  end
end
