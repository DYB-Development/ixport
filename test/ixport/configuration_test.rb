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

  test "a host sets the sign-in check, the person and account methods and the layout in a configure block" do
    Ixport.configure do |config|
      config.authentication_method = :require_staff!
      config.current_person_method = :current_member
      config.current_account_method = :current_team
      config.layout = "back_office"
    end

    assert_equal [ :require_staff!, :current_member, :current_team, "back_office" ],
                 Ixport.configuration.then { |c| [ c.authentication_method, c.current_person_method, c.current_account_method, c.layout ] }
  end
end
