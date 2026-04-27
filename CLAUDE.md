# lex-tick

**Level 3 Documentation**
- **Parent**: `../CLAUDE.md`
- **Grandparent**: `../../CLAUDE.md`

## Purpose

Atomic cognitive processing cycle for the LegionIO brain-modeled agentic architecture. This is the central orchestrator — every cognitive operation runs within a tick. `lex-tick` owns mode management, phase sequencing, timing budget enforcement, and mode transition logic.

## Gem Info

- **Gem name**: `lex-tick`
- **Version**: `0.1.16`
- **Module**: `Legion::Extensions::Tick`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/tick/
  version.rb
  helpers/
    constants.rb     # MODES, PHASES, MODE_PHASES, timing budgets, thresholds
    jitter.rb        # Jitter helper for tick timing
    state.rb         # State class - persists tick_count, mode, signal timestamps
  runners/
    orchestrator.rb  # execute_tick, evaluate_mode_transition, tick_status, set_mode
  actors/
    tick.rb          # Tick actor (runs the orchestrator loop)
  client.rb
spec/
```

## Key Concepts

### Four Modes

| Mode | Tick Budget | Phases Run | Notes |
|------|------------|-----------|-------|
| `:dormant` | 0.2s | `memory_consolidation` only | Minimal processing |
| `:dormant_active` | 5.0s | 10 dream phases | Bounded idle consolidation cycle via lex-dream |
| `:sentinel` | 0.5s | 5 phases (sensing + prediction + consolidation) | Low-activity monitoring |
| `:full_active` | 5.0s | all 16 phases | Full cognitive engagement |

### Phase Sequencing

`Constants::MODE_PHASES` maps mode to phase list. `Orchestrator#execute_tick` iterates phases, checking elapsed time against budget, calling `phase_handlers[phase]` if provided. Missing handlers return `{ status: :no_handler }`.

### Mode Transitions

`evaluate_mode_transition` is called at the start of each tick before phases run. It reads `state.seconds_since_signal` and `state.seconds_since_high_salience` against `SENTINEL_TIMEOUT` (3600s) and `ACTIVE_TIMEOUT` (300s). Emergency triggers bypass all thresholds.

### `set_mode` — Sticky for One Cycle

`set_mode(mode:)` forces the mode AND sets `@mode_forced = true`, which causes the next `execute_tick` to skip automatic mode evaluation for exactly one cycle. `@mode_forced` is cleared at the start of `execute_tick_impl`. This prevents the mode from being immediately overridden by signal-driven transitions on the first tick after a forced change.

## Constants

- `HIGH_SALIENCE_THRESHOLD = 0.7`
- `EMERGENCY_TRIGGERS = %i[firmware_violation extinction_protocol]`
- `MAX_TICK_DURATION = 5.0`
- `SENTINEL_TICK_BUDGET = 0.5`
- `DORMANT_TICK_BUDGET = 0.2`
- `EMERGENCY_PROMOTION_BUDGET = 0.05`
- `DREAM_IDLE_THRESHOLD = 1800` (seconds dormant with no signal before entering dream cycle)
- `SENTINEL_TO_DREAM_THRESHOLD = 600` (seconds sentinel with no signal before entering dream cycle)
- `DREAM_BACKOFF_INTERVAL = 1800` (seconds after a completed dream before another dream cycle)
- `DREAM_TICK_BUDGET = 5.0` (seconds for a dormant-active dream tick)
- `ACTIVE_TIMEOUT = 300` (seconds without high-salience before demotion from full_active)
- `SENTINEL_TIMEOUT = 3600` (seconds without any signal before demotion to dormant)

## 16 Active Phases (full_active)

```ruby
PHASES = %i[
  sensory_processing         # 12% budget
  emotional_evaluation       # 8%
  memory_retrieval           # 12%
  knowledge_retrieval        # 5%
  identity_entropy_check     # 4%
  working_memory_integration # 5%
  procedural_check           # 8%
  prediction_engine          # 12%
  mesh_interface             # 4%
  social_cognition           # 4%
  theory_of_mind             # 4%
  gut_instinct               # 4%
  action_selection           # 4%
  memory_consolidation       # 4%
  homeostasis_regulation     # 5%
  post_tick_reflection       # 5%
]
```

Phase budgets are informational — `run_phases` enforces the tick-level budget only (time checked before each phase, not preempted mid-phase).

## 10 Dream Phases (dormant_active)

```ruby
DREAM_PHASES = %i[
  memory_audit
  association_walk
  contradiction_resolution
  identity_entropy_check
  agenda_formation
  consolidation_commit
  knowledge_promotion
  dream_reflection
  partner_reflection
  dream_narration
]
```

## 5 Sentinel Phases

```ruby
%i[sensory_processing emotional_evaluation memory_retrieval prediction_engine memory_consolidation]
```

## Runner Methods

All in `Runners::Orchestrator`:

| Method | Key Args | Returns |
|--------|----------|---------|
| `execute_tick` | `signals: [], phase_handlers: {}, **context` | `{ tick_number:, mode:, phases_executed:, phases_skipped:, results:, elapsed: }` |
| `evaluate_mode_transition` | `signals: [], emergency: nil, dream_complete: false` | `{ transitioned:, new_mode:, previous_mode:, reason: }` or `{ transitioned: false, current_mode: }` |
| `tick_status` | — | state hash |
| `set_mode` | `mode:` | `{ mode: }` or `{ error: :invalid_mode, valid_modes: }` |

## State Object

`Helpers::State` is instantiated once per orchestrator instance (`@tick_state`):

| Method | What It Does |
|--------|-------------|
| `increment_tick` | clears phase_results, increments tick_count |
| `record_signal(salience:, source_type:)` | updates last_signal_at; updates last_high_salience_at if salience >= 0.7 or source_type == :human_direct |
| `record_phase(phase, result)` | stores result in phase_results hash |
| `transition_to(new_mode)` | updates mode, appends to mode_history (capped at 50) |
| `seconds_since_signal` | elapsed since last_signal_at |
| `seconds_since_high_salience` | elapsed since last_high_salience_at |
| `to_h` | `{ mode:, tick_count:, current_phase:, last_signal_at:, last_high_salience_at:, phases_completed: }` |

## Mode Transition Logic

| From | Condition | To |
|------|-----------|----|
| any | `emergency` in EMERGENCY_TRIGGERS | `:full_active` |
| `:dormant` | any signal present | `:sentinel` |
| `:dormant` | no signal for >= 1800s and dream backoff elapsed | `:dormant_active` |
| `:dormant_active` | salience >= 0.7 or human_direct | `:sentinel` |
| `:dormant_active` | `dream_complete: true`, all dream phases executed, or dream tick deferred | `:dormant` |
| `:sentinel` | salience >= 0.7 or human_direct | `:full_active` |
| `:sentinel` | no signal for >= 3600s | `:dormant` |
| `:sentinel` | no signal for >= 600s and dream backoff elapsed | `:dormant_active` |
| `:full_active` | no high-salience for >= 300s | `:sentinel` |

## Integration with Cognitive Architecture

`lex-tick` calls `phase_handlers` provided at runtime — it does not directly depend on other `lex-*` extensions. The caller (typically the agent runtime) wires in handlers from `lex-emotion`, `lex-memory`, `lex-prediction`, `lex-identity`, `lex-mesh`, etc. This keeps `lex-tick` as a pure orchestrator with no cognitive dependencies.

## Dependencies

**Runtime** (from gemspec):
- `legion-cache` >= 1.3.11
- `legion-crypt` >= 1.4.9
- `legion-data` >= 1.4.17
- `legion-json` >= 1.2.1
- `legion-logging` >= 1.3.2
- `legion-settings` >= 1.3.14
- `legion-transport` >= 1.3.9

**Optional at runtime** (guarded with `defined?`):
- `Legion::Telemetry::OpenInference` — wraps `execute_tick` in an agent span if present

## Development Notes

- State is in-memory; each new `Orchestrator` instance starts fresh
- Phase budget enforcement is best-effort (time checked before each phase, not preempted mid-phase)
- The `phase_handlers` hash uses phase name symbols as keys; unrecognized phases in the handler hash are silently ignored
- `rubocop:disable` on `evaluate_mode_transition` for CyclomaticComplexity — the branching is intentional
