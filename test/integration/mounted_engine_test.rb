# frozen_string_literal: true

require "test_helper"

class MountedEngineTest < ActionDispatch::IntegrationTest
  def setup
    ApplicationController.signed_in_user = User.create!(name: "Rep")
  end

  def teardown
    ApplicationController.signed_in_user = nil
    Ixport.reset_configuration!
  end

  test "serves its pages under the path the host mounts it at" do
    get "/data_imports"

    assert_select "h1", text: "Imports"
  end

  test "draws its pages in the layout the host names" do
    Ixport.configure { |config| config.layout = "back_office" }

    get "/data_imports"

    assert_select "#back-office"
  end
end
