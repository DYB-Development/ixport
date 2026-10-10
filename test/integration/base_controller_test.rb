# frozen_string_literal: true

require "test_helper"

class BaseControllerTest < ActionDispatch::IntegrationTest
  def setup
    ApplicationController.signed_in_user = User.create!(name: "Rep")
  end

  def teardown
    ApplicationController.signed_in_user = nil
  end

  test "the base controller the host names runs its checks before ixport's pages" do
    get "/data_imports"

    assert_equal "checked", response.headers["X-Back-Office"]
  end
end
