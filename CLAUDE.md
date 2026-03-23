# lex-tick

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Atomic cognitive processing cycle for the LegionIO brain-modeled agentic architecture. This is the central orchestrator — every cognitive operation runs within a tick. `lex-tick` owns mode management, phase sequencing, timing budget enforcement, and mode transition logic.

## Gem Info

- **Gem name**: `lex-tick`
- **Version**: `0.1.2`
- **Module**: `Legion::Extensions::Tick`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/tick/
  version.rb
  helpers/
    constants.rb     # MODES, PHASES, MODE_PHASES, timing budgets, thresholds
    state.rb         # State class - persists tick_count, mode, signal timestamps
  runners/
    orchestrator.rb  # execute_tick, evaluate_mode_transition, tick_status, set_mode
spec/
  legion/extensions/tick/
    helpers/
      constants_spec.rb
      state_spec.rb
    runners/
      orchestrator_spec.rb
    client_spec.rb
```

## Key Concepts

### Four Modes
- `:dormant` - 0.2s budget, only `memory_consolidation` runs
- `:dormant_active` - uncapped budget, 8 dream phases run (idle consolidation cycle via lex-dream)
- `:sentinel` - 0.5s budget, 5 phases run (sensing + prediction + consolidation)
- `:full_active` - 5.0s budget, all 12 phases run

### Phase Sequencing
`Constants::MODE_PHASES` maps mode to phase list. `Orchestrator#execute_tick` iterates phases, checking elapsed time against budget, calling `phase_handlers[phase]` if provided. Missing handlers return `{ status: :no_handler }`.

### Mode Transitions
`evaluate_mode_transition` is called at the start of each tick before phases run. It reads `state.seconds_since_signal` and `state.seconds_since_high_salience` against `SENTINEL_TIMEOUT` (3600s) and `ACTIVE_TIMEOUT` (300s). Emergency triggers bypass all thresholds.

### Constants
- `HIGH_SALIENCE_THRESHOLD = 0.7`
- `EMERGENCY_TRIGGERS = %i[firmware_violation extinction_protocol]`
- `MAX_TICK_DURATION = 5.0`
- `SENTINEL_TICK_BUDGET = 0.5`
- `DORMANT_TICK_BUDGET = 0.2`
- `EMERGENCY_PROMOTION_BUDGET = 0.05`
- `DREAM_IDLE_THRESHOLD = 1800` (seconds dormant with no signal before entering dream cycle)
- `SENTINEL_TO_DREAM_THRESHOLD = 600` (seconds sentinel with no signal before entering dream cycle)

## 12 Active Phases (full_active)

```
PHASES = %i[
  sensory_processing        # 15% budget
  emotional_evaluation      # 10%
  memory_retrieval          # 20%
  identity_entropy_check    # 5%
  working_memory_integration # 5%
  procedural_check          # 10%
  prediction_engine         # 15%
  mesh_interface            # 5%
  gut_instinct              # 5%
  action_selection          # 5%
  memory_consolidation      # 5%
  post_tick_reflection      # 5%
]
```

## 8 Dream Phases (dormant_active)

```
DREAM_PHASES = %i[
  memory_audit
  association_walk
  contradiction_resolution
  identity_entropy_check
  agenda_formation
  consolidation_commit
  dream_reflection
  dream_narration
]
```

## Runner Methods

All in `Runners::Orchestrator`:
- `execute_tick(signals:, phase_handlers:)` - run one tick cycle
- `evaluate_mode_transition(signals:, emergency:)` - check/apply mode transition
- `tick_status` - returns state hash
- `set_mode(mode:)` - force a specific mode (validation included)

## State Object

`Helpers::State` is instantiated once per orchestrator instance (`@tick_state`):
- `increment_tick` - clears phase_results, increments tick_count
- `record_signal(salience:)` - updates last_signal_at, conditionally last_high_salience_at
- `record_phase(phase, result)` - stores result in phase_results hash
- `transition_to(new_mode)` - updates mode, appends to mode_history (capped at 50)

## Integration with Cognitive Architecture

`lex-tick` calls `phase_handlers` provided at runtime — it does not directly depend on other `lex-*` extensions. The caller (typically the agent runtime) wires in handlers from `lex-emotion`, `lex-memory`, `lex-prediction`, `lex-identity`, `lex-mesh`, etc. This keeps `lex-tick` as a pure orchestrator with no cognitive dependencies.

## Development Notes

- State is in-memory; each new `Orchestrator` instance starts fresh
- Phase budget enforcement is best-effort (time checked before each phase, not preempted mid-phase)
- The `phase_handlers` hash uses phase name symbols as keys; unrecognized phases in the handler hash are silently ignored
- `rubocop:disable` on `evaluate_mode_transition` for CyclomaticComplexity — the branching is intentional
