# frozen_string_literal: true

require_relative "lib/sorbet_operation/version"

Gem::Specification.new do |spec|
  spec.name = "sorbet_operation"
  spec.version = SorbetOperation::VERSION
  spec.authors = ["Thatch Health, Inc."]
  spec.email = ["sorbet-operation@thatch.ai"]

  spec.summary = "Sorbet-powered operation framework."
  spec.description = "sorbet_operation is a minimal operation framework that leverages Sorbet's type system to " \
    "ensure that operations are well-typed and that their inputs and outputs are well-defined."
  spec.homepage = "https://github.com/thatch-health/sorbet_operation"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/thatch-health/sorbet_operation/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    %x(git ls-files -z).split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features|sorbet)/|\.(?:git|circleci|vscode)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_runtime_dependency("sorbet-runtime", "~> 0.5.10741")

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
