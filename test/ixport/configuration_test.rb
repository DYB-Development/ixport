# frozen_string_literal: true

require "test_helper"

class Ixport::ConfigurationTest < ActiveSupport::TestCase
  def teardown
    Ixport.reset_configuration!
  end

  test "checks sign-in through authenticate_user! unless the host names another method" do
    assert_equal :authenticate_user!, Ixport.configuration.authentication_method
  end

  test "finds the current person through current_user unless the host names another method" do
    assert_equal :current_user, Ixport.configuration.current_person_method
  end

  test "finds the current account through current_account unless the host names another method" do
    assert_equal :current_account, Ixport.configuration.current_account_method
  end

  test "draws pages in the application layout unless the host names another" do
    assert_equal "application", Ixport.configuration.layout
  end
end
