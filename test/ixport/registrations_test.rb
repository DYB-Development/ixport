# frozen_string_literal: true

require "test_helper"

class Ixport::RegistrationsTest < ActiveSupport::TestCase
  def teardown
    Ixport.reset_registrations!
  end

  test "a host registers a mapped import by its key, its title and the name of its importer class" do
    Ixport.register_import(:products, title: "Products", importer: "ProductImporter")

    assert_equal [ "Products", "ProductImporter" ], [ Ixport.registration(:products).title, Ixport.registration(:products).importer ]
  end

  test "a registered import whose importer class does not exist raises an error naming the class" do
    Ixport.register_import(:products, title: "Products", importer: "MissingProductImporter")

    error = assert_raises(Ixport::MissingImporter) { Ixport.check_registrations! }

    assert_includes error.message, "MissingProductImporter"
  end

  test "a host registers a fixed export by its key, its title and the name of its exporter class" do
    Ixport.register_export(:products, title: "Products", exporter: "ProductExporter")

    assert_equal [ "Products", "ProductExporter" ], [ Ixport.export_registration(:products).title, Ixport.export_registration(:products).exporter ]
  end
end
