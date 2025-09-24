# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in sorbet_operation.gemspec
gemspec

gem "rake", "~> 13.0"

gem "benchmark" # for Ruby >= 3.5
gem "bigdecimal" # for Ruby >= 3.4
gem "ostruct" # for Ruby >= 3.5

group :development, :test do
  gem "irb"
end

group :development do
  gem "sorbet", "~> 0.5.10736"
  gem "tapioca", require: false

  gem "rubocop", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-shopify", require: false
  gem "rubocop-sorbet", require: false

  gem "bundler-audit", require: false
end

group :test do
  gem "minitest", "~> 5.0"
  gem "minitest-reporters", "~> 1.4"

  gem "simplecov", require: false
end

group :docs do
  gem "yard"
  gem "yard-sorbet"
end
