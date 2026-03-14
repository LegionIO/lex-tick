# lex-tick

Atomic cognitive processing cycle for brain-modeled agentic AI. Implements the core tick loop with 11 phases, 4 operating modes, and mode transition logic.

## Overview

`lex-tick` is the central orchestrator of the LegionIO cognitive architecture. Every cognitive action the agent performs happens within a tick. A tick advances the agent's internal state, runs the appropriate phases for the current mode, and produces a result record.

## Operating Modes

The agent operates in one of four modes at any time:

| Mode | Description | Phases Run | Tick Budget |
|------|-------------|------------|-------------|
| `dormant` | No active signals | `memory_consolidation` only | 0.2s |
| `dormant_active` | Dream cycle — idle consolidation | 6 dream phases | uncapped |
| `sentinel` | Low-activity monitoring | 5 phases | 0.5s |
| `full_active` | Full cognitive engagement | All 11 phases | 5.0s |

Mode transitions are driven by signal salience thresholds and time-since-signal:
- Any signal: `dormant` -> `sentinel`
- High salience (>= 0.7) or human direct input: `sentinel` -> `full_active`
- No high-salience signal for 300s: `full_active` -> `sentinel`
- No signal for 1800s while dormant: `dormant` -> `dormant_active` (dream cycle)
- No signal for 3600s: `sentinel` -> `dormant`
- Emergency trigger (`:firmware_violation`, `:extinction_protocol`): immediate `full_active`

## 11 Phases (full_active)

1. `sensory_processing` (15% budget)
2. `emotional_evaluation` (10%)
3. `memory_retrieval` (20%)
4. `identity_entropy_check` (5%)
5. `working_memory_integration` (5%)
6. `procedural_check` (10%)
7. `prediction_engine` (15%)
8. `mesh_interface` (5%)
9. `gut_instinct` (5%)
10. `action_selection` (5%)
11. `memory_consolidation` (5%)

## Installation

Add to your Gemfile:

```ruby
gem 'lex-tick'
```

## Usage

```ruby
require 'legion/extensions/tick'

# Execute a tick with signals and phase handlers
result = Legion::Extensions::Tick::Runners::Orchestrator.execute_tick(
  signals: [{ salience: 0.8, source_type: :human_direct, content: "Hello" }],
  phase_handlers: {
    sensory_processing: ->(state:, signals:, prior_results:) {
      { processed: signals.size }
    },
    action_selection: ->(state:, signals:, prior_results:) {
      { action: :respond }
    }
  }
)

# Check mode
result[:mode]            # => :full_active
result[:tick_number]     # => 1
result[:phases_executed] # => [:sensory_processing, ..., :memory_consolidation]
result[:elapsed]         # => 0.001

# Check/set mode
Legion::Extensions::Tick::Runners::Orchestrator.tick_status
Legion::Extensions::Tick::Runners::Orchestrator.set_mode(mode: :sentinel)

# Force mode transition for emergency
Legion::Extensions::Tick::Runners::Orchestrator.evaluate_mode_transition(
  emergency: :firmware_violation
)
```

## State Object

The `State` object (`Helpers::State`) persists across ticks and tracks:

- `mode` - current operating mode
- `tick_count` - total ticks executed
- `last_signal_at` / `last_high_salience_at` - timestamps driving mode decay
- `phase_results` - results from the current tick's phases
- `mode_history` - last 50 mode transitions with timestamps

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
