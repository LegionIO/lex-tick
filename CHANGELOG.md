# Changelog

## [0.1.10] - 2026-03-30

### Fixed
- Add `remote_invocable?` spec to `orchestrator_spec.rb` to prevent regressions on local-dispatch enforcement

## [0.1.9] - 2026-03-30

### Changed
- add rubocop-legion 0.1.7, resolve all offenses

## [0.1.8] - 2026-03-26

### Changed
- fix remote_invocable? to use class method for local dispatch

## [0.1.7] - 2026-03-24

### Added
- `social_cognition`, `theory_of_mind`, and `homeostasis_regulation` phases added to `PHASES` constant (now 16 phases in `full_active` mode)
- Phase budgets redistributed across 16 phases (sum remains 1.0)

## [0.1.6] - 2026-03-24

### Added
- `knowledge_retrieval` phase added to `PHASES` constant (now 13 phases in `full_active` mode)
- `knowledge_retrieval` added to `PHASE_BUDGETS` with 0.05 budget (redistributed from `memory_retrieval` 0.20 -> 0.15)

### Fixed
- `knowledge_retrieval` was defined in GAIA's `PHASE_MAP` but absent from lex-tick's `PHASES` array, making it unreachable during tick execution

## [0.1.5] - 2026-03-23

### Changed
- Add `knowledge_promotion` to DREAM_PHASES (9 phases, was 8) to match dream cycle Apollo integration

## [0.1.4] - 2026-03-22

### Changed
- Downgrade tick complete log line from info to debug level

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
