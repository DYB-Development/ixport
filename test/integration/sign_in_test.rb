# frozen_string_literal: true

require "test_helper"

class SignInTest < ActionDispatch::IntegrationTest
  test "sends a person who is not signed in through the host's sign-in check" do
    get "/data_imports"

    assert_response :unauthorized
  end
end
