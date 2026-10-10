# frozen_string_literal: true

require "test_helper"

class Ixport::ConfigurationTest < ActiveSupport::TestCase
  def teardown
    Ixport.reset_configuration!
  end

  test "checks sign-in through authenticate_user! unless the host names another method" do
    assert_equal :authenticate_user!, Ixport.configuration.authentication_method
  end
end
