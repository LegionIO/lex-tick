# Changelog

## [0.1.3] - 2026-03-22

### Changed
- Add legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport as runtime dependencies
- Replace direct Legion::Logging calls with injected log helper in runners/orchestrator
- Update spec_helper with real sub-gem helper stubs

## [0.1.2] - 2026-03-21

### Fixed
- Remove local path dependency on legion-gaia (use RubyGems)
- Move legion-gaia dev dependency from gemspec to Gemfile (RuboCop Gemspec/DevelopmentDependencies)

## [0.1.1] - 2026-03-20

### Added
- OpenInference AGENT span wrapping for execute_tick orchestrator
- `spec/legion/extensions/tick/actors/tick_spec.rb` (12 examples) — tests for the Tick actor (Every 1s)

## [0.1.0] - 2026-03-13

### Added
- Initial release
