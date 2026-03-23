# frozen_string_literal: true

require_relative 'lib/legion/extensions/tick/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-tick'
  spec.version       = Legion::Extensions::Tick::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Tick'
  spec.description   = 'Atomic cognitive processing cycle (11 phases, 3 modes) for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-tick'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-tick'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-tick'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-tick'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-tick/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-tick.gemspec Gemfile]
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'legion-cache',     '>= 1.3.11'
  spec.add_dependency 'legion-crypt',     '>= 1.4.9'
  spec.add_dependency 'legion-data',      '>= 1.4.17'
  spec.add_dependency 'legion-json',      '>= 1.2.1'
  spec.add_dependency 'legion-logging',   '>= 1.3.2'
  spec.add_dependency 'legion-settings',  '>= 1.3.14'
  spec.add_dependency 'legion-transport', '>= 1.3.9'
end
