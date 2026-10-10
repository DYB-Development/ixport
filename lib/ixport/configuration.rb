# frozen_string_literal: true

module Ixport
  class Configuration
    attr_accessor :authentication_method, :current_person_method, :current_account_method

    def initialize
      @authentication_method = :authenticate_user!
      @current_person_method = :current_user
      @current_account_method = :current_account
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end
end
