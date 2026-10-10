# frozen_string_literal: true

module Ixport
  class ApplicationController < ::ApplicationController
    before_action { send(Ixport.configuration.authentication_method) }
    layout -> { Ixport.configuration.layout }

    private

    def allowed?(registration)
      registration.allows?(ixport_person, ixport_account)
    end

    def find_import
      @import = Import.find_by(id: params[:import_id] || params[:id], person: ixport_person, account: ixport_account)
      head :not_found unless @import && allowed?(Ixport.registration(@import.key))
    end

    def ixport_person
      send(Ixport.configuration.current_person_method)
    end

    def ixport_account
      send(Ixport.configuration.current_account_method)
    end
  end
end
