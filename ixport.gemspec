require_relative "lib/ixport/version"

Gem::Specification.new do |spec|
  spec.name = "ixport"
  spec.version = Ixport::VERSION
  spec.authors = [ "Tyler Schneider" ]
  spec.email = [ "tylercschneider@gmail.com" ]
  spec.homepage = "https://github.com/DYB-Development/ixport"
  spec.summary = "CSV import and export for Rails apps."
  spec.description = "A Rails engine that lets a person import records into a Rails app from a CSV file and export them to one."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "#{spec.homepage}#readme"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,the_local}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "keystone_ui", ">= 0.38.0"
  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "activesupport", ">= 7.0"
end
