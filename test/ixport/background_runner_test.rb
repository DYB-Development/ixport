# frozen_string_literal: true

require "test_helper"

class Ixport::BackgroundRunnerTest < ActiveSupport::TestCase
  def teardown
    Ixport.reset_configuration!
    Wallflower.reset_kinds!
  end

  test "a developer can configure wallflower as ixport's background runner" do
    Ixport.configure { |config| config.background_runner = :wallflower }

    Ixport.install_background_runner!

    assert_equal "Ixport::WallflowerTaskRunner", Wallflower.kind(:ixport_import).runner
  end
end
