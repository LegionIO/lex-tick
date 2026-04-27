# frozen_string_literal: true

module Legion
  module Extensions
    module Tick
      module Helpers
        module Constants
          # Tick modes
          MODES = %i[dormant dormant_active sentinel full_active].freeze

          # 16 phases of a full active tick
          PHASES = %i[
            sensory_processing
            emotional_evaluation
            memory_retrieval
            knowledge_retrieval
            identity_entropy_check
            working_memory_integration
            procedural_check
            prediction_engine
            mesh_interface
            social_cognition
            theory_of_mind
            gut_instinct
            action_selection
            memory_consolidation
            homeostasis_regulation
            post_tick_reflection
          ].freeze

          # Phases for dream cycle (dormant_active mode)
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
          ].freeze

          # Which phases run in each mode
          MODE_PHASES = {
            dormant:        %i[memory_consolidation],
            dormant_active: DREAM_PHASES,
            sentinel:       %i[sensory_processing emotional_evaluation memory_retrieval prediction_engine memory_consolidation],
            full_active:    PHASES
          }.freeze

          # Timing constants (in seconds)
          ACTIVE_TIMEOUT                = 300    # seconds without high-salience signal before demotion
          SENTINEL_TIMEOUT              = 3600   # seconds without any signal before demotion to dormant
          DREAM_IDLE_THRESHOLD          = 1800   # seconds dormant with no signal before entering dream cycle
          SENTINEL_TO_DREAM_THRESHOLD   = 600    # seconds sentinel with no signal before entering dream cycle
          DREAM_BACKOFF_INTERVAL        = 1800   # seconds after a completed dream before another dream cycle
          MAX_TICK_DURATION             = 5.0    # hard ceiling for full active tick (seconds)
          DREAM_TICK_BUDGET             = 5.0    # hard ceiling for dormant-active dream tick (seconds)
          SENTINEL_TICK_BUDGET          = 0.5    # time budget for sentinel tick
          DORMANT_TICK_BUDGET           = 0.2    # time budget for dormant tick
          EMERGENCY_PROMOTION_BUDGET    = 0.05   # max latency for emergency mode promotion

          # Phase timing budgets (fraction of total tick time).
          # Informational only — not enforced by run_phases, which uses the tick-level budget.
          # Useful as a reference for callers that want to self-limit within a phase handler.
          PHASE_BUDGETS = {
            sensory_processing:         0.12,
            emotional_evaluation:       0.08,
            memory_retrieval:           0.12,
            knowledge_retrieval:        0.05,
            identity_entropy_check:     0.04,
            working_memory_integration: 0.05,
            procedural_check:           0.08,
            prediction_engine:          0.12,
            mesh_interface:             0.04,
            social_cognition:           0.04,
            theory_of_mind:             0.04,
            gut_instinct:               0.04,
            action_selection:           0.04,
            memory_consolidation:       0.04,
            homeostasis_regulation:     0.05,
            post_tick_reflection:       0.05
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
            when :dormant        then DORMANT_TICK_BUDGET
            when :dormant_active then DREAM_TICK_BUDGET
            when :sentinel       then SENTINEL_TICK_BUDGET
            else                      MAX_TICK_DURATION
            end
          end
        end
      end
    end
  end
end
