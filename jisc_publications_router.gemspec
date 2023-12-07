# frozen_string_literal: true

require_relative "lib/jisc_publications_router/version"

Gem::Specification.new do |spec|
  spec.name          = "jisc_publications_router"
  spec.version       = JiscPublicationsRouter::VERSION
  spec.authors       = ["Anusha Ranganathan"]
  spec.email         = ["anusha@cottagelabs.com"]

  spec.summary       = "API client for JISC publications router"
  spec.description   = "Rails gem for interaction with the JISC Publications router API"
  spec.homepage      = "https://gitlab.bodleian.ox.ac.uk/ORA4/jisc-publications-router"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://gitlab.bodliena.ox.ac.uk/ORA4/jisc-publications-router"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://gitlab.bodliena.ox.ac.uk/ORA4/jisc-publications-router"
  spec.metadata["changelog_uri"] = "https://gitlab.bodliena.ox.ac.uk/ORA4/jisc-publications-router/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "byebug"
  spec.add_dependency "net-http-persistent"
  spec.add_dependency "rspec"
  spec.add_dependency "sidekiq", "5.2.8"
  spec.add_dependency "webmock"
  spec.add_dependency "down", "~> 5.0"
end
