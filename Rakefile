# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"
require "yard"
require "bundler/audit/task"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end
task default: :test

RuboCop::RakeTask.new do |t|
  t.options = ["--parallel"]
end

YARD::Rake::YardocTask.new

Bundler::Audit::Task.new
