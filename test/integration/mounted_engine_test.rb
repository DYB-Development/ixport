# frozen_string_literal: true

require "test_helper"

class MountedEngineTest < ActionDispatch::IntegrationTest
  test "serves its pages under the path the host mounts it at" do
    get "/data_imports"

    assert_select "h1", text: "Imports"
  end
end
