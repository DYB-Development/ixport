# frozen_string_literal: true

module Ixport
  class ApplicationController < Ixport.configuration.base_controller.constantize
    before_action { send(Ixport.configuration.authentication_method) }
    layout -> { Ixport.configuration.layout }

    private

    def allowed?(registration, target = nil)
      registration.allows?(ixport_person, ixport_account, target)
    end

    def find_import
      @import = Import.find_by(id: params[:import_id] || params[:id], person: ixport_person, account: ixport_account)
      registration = @import && Ixport.registrations[@import.key.to_sym]
      head :not_found unless registration && allowed?(registration, @import.target)
    end

    def ixport_person
      send(Ixport.configuration.current_person_method)
    end

    def ixport_account
      send(Ixport.configuration.current_account_method)
    end
  end
end
