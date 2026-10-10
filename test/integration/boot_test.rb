# frozen_string_literal: true

require "test_helper"
require "open3"

class BootTest < ActiveSupport::TestCase
  BOOT_WITH_MISSING_IMPORTER = <<~RUBY
    require "./test/dummy/config/application"
    Ixport.register_import(:products, title: "Products", importer: "MissingProductImporter")
    Rails.application.initialize!
  RUBY

  test "a host that registers an importer which does not exist fails to boot with a message naming it" do
    _output, error, _status = Open3.capture3({ "RAILS_ENV" => "test" }, "ruby", "-e", BOOT_WITH_MISSING_IMPORTER, chdir: File.expand_path("../..", __dir__))

    assert_includes error, "names the importer MissingProductImporter"
  end
end
