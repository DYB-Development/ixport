source "https://rubygems.org"

gemspec

gem "rake"
gem "rails"
gem "minitest", "~> 5.0"  # pin to 5.x; minitest 6 removed minitest/mock
gem "sqlite3"
gem "rubocop-rails-omakase", require: false
gem "the_local", "~> 0.4"
gem "keystone_ui", ">= 0.38.0" # listed here too so the_local installs its agents

# json 3.0.2 broke ActiveSupport JSON decoding
gem "json", "~> 2.21", ">= 2.21.2"
