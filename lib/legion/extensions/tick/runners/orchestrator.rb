# frozen_string_literal: true

module Legion
  module Extensions
    module Tick
      module Runners
        module Orchestrator
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def execute_tick(signals: [], phase_handlers: {}, **)
            state = tick_state
            state.increment_tick

            # Record incoming signals
            max_salience = signals.map { |s| s.is_a?(Hash) ? (s[:salience] || 0.0) : 0.0 }.max || 0.0
            state.record_signal(salience: max_salience) unless signals.empty?

            # Evaluate mode transitions before tick
            evaluate_mode_transition(signals: signals)

            phases = Helpers::Constants.phases_for_mode(state.mode)
            budget = Helpers::Constants.tick_budget(state.mode)
            start_time = Time.now.utc
            results = {}

            phases.each do |phase|
              elapsed = Time.now.utc - start_time
              break if elapsed >= budget

              handler = phase_handlers[phase]
              result = if handler
                         handler.call(state: state, signals: signals, prior_results: results)
                       else
                         { status: :no_handler }
                       end

              state.record_phase(phase, result)
              results[phase] = result
            end

            {
              tick_number:      state.tick_count,
              mode:             state.mode,
              phases_executed:  results.keys,
              phases_skipped:   phases - results.keys,
              results:          results,
              elapsed:          Time.now.utc - start_time
            }
          end

          def evaluate_mode_transition(signals: [], emergency: nil, **)
            state = tick_state

            # Emergency promotion
            if emergency && Helpers::Constants::EMERGENCY_TRIGGERS.include?(emergency)
              state.transition_to(:full_active)
              return { transitioned: true, new_mode: :full_active, reason: :emergency }
            end

            # Check signal-based promotions
            max_salience = signals.map { |s| s.is_a?(Hash) ? (s[:salience] || 0.0) : 0.0 }.max || 0.0
            has_human = signals.any? { |s| s.is_a?(Hash) && s[:source_type] == :human_direct }

            new_mode = case state.mode
                       when :dormant
                         if signals.any?
                           :sentinel
                         else
                           :dormant
                         end
                       when :sentinel
                         if has_human || max_salience >= Helpers::Constants::HIGH_SALIENCE_THRESHOLD
                           :full_active
                         elsif state.seconds_since_signal >= Helpers::Constants::SENTINEL_TIMEOUT
                           :dormant
                         else
                           :sentinel
                         end
                       when :full_active
                         if state.seconds_since_high_salience >= Helpers::Constants::ACTIVE_TIMEOUT
                           :sentinel
                         else
                           :full_active
                         end
                       end

            if new_mode != state.mode
              state.transition_to(new_mode)
              { transitioned: true, new_mode: new_mode, reason: :threshold }
            else
              { transitioned: false, current_mode: state.mode }
            end
          end

          def tick_status(**)
            tick_state.to_h
          end

          def set_mode(mode:, **)
            unless Helpers::Constants::MODES.include?(mode)
              return { error: :invalid_mode, valid_modes: Helpers::Constants::MODES }
            end

            tick_state.transition_to(mode)
            { mode: mode }
          end

          private

          def tick_state
            @tick_state ||= Helpers::State.new
          end
        end
      end
    end
  end
end
