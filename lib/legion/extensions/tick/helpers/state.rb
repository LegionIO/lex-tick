# frozen_string_literal: true

module Legion
  module Extensions
    module Tick
      module Helpers
        class State
          attr_reader :mode, :tick_count, :last_signal_at, :last_high_salience_at,
                      :phase_results, :current_phase, :mode_history

          def initialize(mode: :dormant)
            @mode = mode
            @tick_count = 0
            @last_signal_at = nil
            @last_high_salience_at = nil
            @phase_results = {}
            @current_phase = nil
            @mode_history = [{ mode: mode, at: Time.now.utc }]
          end

          def record_signal(salience: 0.0)
            @last_signal_at = Time.now.utc
            @last_high_salience_at = Time.now.utc if salience >= Constants::HIGH_SALIENCE_THRESHOLD
          end

          def record_phase(phase, result)
            @current_phase = phase
            @phase_results[phase] = result
          end

          def increment_tick
            @tick_count += 1
            @phase_results = {}
            @current_phase = nil
          end

          def transition_to(new_mode)
            return if new_mode == @mode

            @mode = new_mode
            @mode_history << { mode: new_mode, at: Time.now.utc }
            @mode_history.shift while @mode_history.size > 50
          end

          def seconds_since_signal
            return Float::INFINITY unless @last_signal_at

            Time.now.utc - @last_signal_at
          end

          def seconds_since_high_salience
            return Float::INFINITY unless @last_high_salience_at

            Time.now.utc - @last_high_salience_at
          end

          def to_h
            {
              mode:                  @mode,
              tick_count:            @tick_count,
              current_phase:         @current_phase,
              last_signal_at:        @last_signal_at,
              last_high_salience_at: @last_high_salience_at,
              phases_completed:      @phase_results.keys
            }
          end
        end
      end
    end
  end
end
