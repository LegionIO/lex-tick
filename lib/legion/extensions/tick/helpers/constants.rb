# frozen_string_literal: true

module Legion
  module Extensions
    module Tick
      module Helpers
        module Constants
          # Tick modes
          MODES = %i[dormant sentinel full_active].freeze

          # 11 phases of a full active tick
          PHASES = %i[
            sensory_processing
            emotional_evaluation
            memory_retrieval
            identity_entropy_check
            working_memory_integration
            procedural_check
            prediction_engine
            mesh_interface
            gut_instinct
            action_selection
            memory_consolidation
          ].freeze

          # Which phases run in each mode
          MODE_PHASES = {
            dormant:     %i[memory_consolidation],
            sentinel:    %i[sensory_processing emotional_evaluation memory_retrieval prediction_engine memory_consolidation],
            full_active: PHASES
          }.freeze

          # Timing constants (in seconds)
          ACTIVE_TIMEOUT           = 300    # seconds without high-salience signal before demotion
          SENTINEL_TIMEOUT         = 3600   # seconds without any signal before demotion to dormant
          MAX_TICK_DURATION        = 5.0    # hard ceiling for full active tick (seconds)
          SENTINEL_TICK_BUDGET     = 0.5    # time budget for sentinel tick
          DORMANT_TICK_BUDGET      = 0.2    # time budget for dormant tick
          EMERGENCY_PROMOTION_BUDGET = 0.05 # max latency for emergency mode promotion

          # Phase timing budgets (fraction of total tick time)
          PHASE_BUDGETS = {
            sensory_processing:         0.15,
            emotional_evaluation:       0.10,
            memory_retrieval:           0.20,
            identity_entropy_check:     0.05,
            working_memory_integration: 0.05,
            procedural_check:           0.10,
            prediction_engine:          0.15,
            mesh_interface:             0.05,
            gut_instinct:               0.05,
            action_selection:           0.05,
            memory_consolidation:       0.05
          }.freeze

          # Salience thresholds for mode transitions
          HIGH_SALIENCE_THRESHOLD = 0.7
          EMERGENCY_TRIGGERS = %i[firmware_violation extinction_protocol].freeze

          module_function

          def phases_for_mode(mode)
            MODE_PHASES.fetch(mode, PHASES)
          end

          def tick_budget(mode)
            case mode
            when :dormant  then DORMANT_TICK_BUDGET
            when :sentinel then SENTINEL_TICK_BUDGET
            else                MAX_TICK_DURATION
            end
          end
        end
      end
    end
  end
end
