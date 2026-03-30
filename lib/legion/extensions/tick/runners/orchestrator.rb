# frozen_string_literal: true

module Legion
  module Extensions
    module Tick
      module Runners
        module Orchestrator
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex, false)

          def self.remote_invocable?
            false
          end

          def execute_tick(signals: [], phase_handlers: {}, **)
            if defined?(Legion::Telemetry::OpenInference)
              state = tick_state
              Legion::Telemetry::OpenInference.agent_span(
                name: "tick-#{state.tick_count + 1}", mode: state.mode,
                phase_count: Helpers::Constants.phases_for_mode(state.mode).size,
                budget_ms: (Helpers::Constants.tick_budget(state.mode) * 1000).round
              ) { |_span| execute_tick_impl(signals: signals, phase_handlers: phase_handlers) }
            else
              execute_tick_impl(signals: signals, phase_handlers: phase_handlers)
            end
          end

          def evaluate_mode_transition(signals: [], emergency: nil, dream_complete: false, **) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            state = tick_state
            previous_mode = state.mode

            # Emergency promotion
            if emergency && Helpers::Constants::EMERGENCY_TRIGGERS.include?(emergency)
              log.warn "[tick] emergency promotion triggered: #{emergency}"
              state.transition_to(:full_active)
              return { transitioned: true, new_mode: :full_active, previous_mode: previous_mode, reason: :emergency }
            end

            # Check signal-based promotions
            max_salience = signals.map { |s| s.is_a?(Hash) ? (s[:salience] || 0.0) : 0.0 }.max || 0.0
            has_human = signals.any? { |s| s.is_a?(Hash) && s[:source_type] == :human_direct }

            new_mode = case state.mode
                       when :dormant
                         if signals.any?
                           :sentinel
                         elsif state.seconds_since_signal >= Helpers::Constants::DREAM_IDLE_THRESHOLD
                           :dormant_active
                         else
                           :dormant
                         end
                       when :dormant_active
                         if max_salience >= Helpers::Constants::HIGH_SALIENCE_THRESHOLD || has_human
                           :sentinel
                         elsif dream_complete
                           :dormant
                         else
                           :dormant_active
                         end
                       when :sentinel
                         if has_human || max_salience >= Helpers::Constants::HIGH_SALIENCE_THRESHOLD
                           :full_active
                         elsif state.seconds_since_signal >= Helpers::Constants::SENTINEL_TO_DREAM_THRESHOLD
                           :dormant_active
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

            if new_mode == state.mode
              { transitioned: false, current_mode: state.mode }
            else
              state.transition_to(new_mode)
              log.info "[tick] mode transition: #{previous_mode} -> #{new_mode} (threshold)"
              { transitioned: true, new_mode: new_mode, previous_mode: previous_mode, reason: :threshold }
            end
          end

          def tick_status(**)
            status = tick_state.to_h
            log.debug "[tick] status query: mode=#{status[:mode]} tick_count=#{status[:tick_count]}"
            status
          end

          def set_mode(mode:, **)
            unless Helpers::Constants::MODES.include?(mode)
              log.warn "[tick] invalid mode requested: #{mode}"
              return { error: :invalid_mode, valid_modes: Helpers::Constants::MODES }
            end

            previous = tick_state.mode
            tick_state.transition_to(mode)
            log.info "[tick] mode forced: #{previous} -> #{mode}"
            { mode: mode }
          end

          private

          def execute_tick_impl(signals:, phase_handlers:)
            state = tick_state
            state.increment_tick

            max_salience = signals.map { |s| s.is_a?(Hash) ? (s[:salience] || 0.0) : 0.0 }.max || 0.0
            state.record_signal(salience: max_salience) unless signals.empty?

            log.debug "[tick] ##{state.tick_count} starting | mode=#{state.mode} signals=#{signals.size} max_salience=#{max_salience.round(2)}"

            transition = evaluate_mode_transition(signals: signals)
            log.info "[tick] mode transition: #{transition[:previous_mode]} -> #{transition[:new_mode]} (#{transition[:reason]})" if transition[:transitioned]

            phases = Helpers::Constants.phases_for_mode(state.mode)
            budget = Helpers::Constants.tick_budget(state.mode)
            start_time = Time.now.utc
            ctx = { budget: budget, start_time: start_time, phase_handlers: phase_handlers, signals: signals }
            results = run_phases(phases, state, ctx)

            total_elapsed = Time.now.utc - start_time
            skipped = phases - results.keys
            log_tick_complete(state, results, phases, total_elapsed, skipped)

            {
              tick_number:     state.tick_count,
              mode:            state.mode,
              phases_executed: results.keys,
              phases_skipped:  skipped,
              results:         results,
              elapsed:         total_elapsed
            }
          end

          def run_phases(phases, state, ctx)
            results = {}
            budget = ctx[:budget]
            start_time = ctx[:start_time]
            log.debug "[tick] ##{state.tick_count} running #{phases.size} phases with #{budget}s budget"
            phases.each do |phase|
              elapsed = Time.now.utc - start_time
              if elapsed >= budget
                log.debug "[tick] ##{state.tick_count} budget exhausted at #{elapsed.round(3)}s, skipping remaining phases"
                break
              end

              result = run_single_phase(phase, ctx[:phase_handlers][phase], state, ctx[:signals], results)
              state.record_phase(phase, result)
              results[phase] = result
            end
            results
          end

          def run_single_phase(phase, handler, state, signals, results)
            phase_start = Time.now.utc
            result = handler ? handler.call(state: state, signals: signals, prior_results: results) : { status: :no_handler }
            phase_elapsed = ((Time.now.utc - phase_start) * 1000).round(1)
            status = result.is_a?(Hash) ? (result[:status] || :ok) : :ok
            log.debug "[tick] ##{state.tick_count} phase=#{phase} status=#{status} (#{phase_elapsed}ms)"
            result
          end

          def log_tick_complete(state, results, phases, total_elapsed, skipped)
            skipped_suffix = skipped.empty? ? '' : " skipped=#{skipped}"
            log.debug "[tick] ##{state.tick_count} complete | mode=#{state.mode} " \
                      "phases=#{results.size}/#{phases.size} " \
                      "elapsed=#{(total_elapsed * 1000).round(1)}ms#{skipped_suffix}"
          end

          def tick_state
            @tick_state ||= Helpers::State.new
          end
        end
      end
    end
  end
end
