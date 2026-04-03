# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Tick
      module Actor
        # Disabled: lex-cortex's Think actor replaces this.
        # Cortex wires phase_handlers from all agentic extensions
        # and calls execute_tick with real handlers instead of empty ones.
        # To use tick standalone (without cortex), re-enable this actor.
        class Tick < Legion::Extensions::Actors::Every
          def initialize(**opts)
            return unless enabled?

            apply_initial_jitter
            super
          end

          def runner_class
            return Legion::Gaia if gaia_heartbeat_available?

            Legion::Extensions::Tick::Runners::Orchestrator
          end

          def runner_function
            return 'heartbeat' if gaia_heartbeat_available?

            'execute_tick'
          end

          def enabled? # rubocop:disable Legion/Extension/ActorEnabledSideEffects
            !Legion::Extensions.const_defined?(:Cortex, false)
          end

          def time
            1
          end

          def run_now?
            true
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end

          def args
            return {} if gaia_heartbeat_available?

            { signals: [], phase_handlers: {} }
          end

          private

          def gaia_heartbeat_available?
            return false unless defined?(Legion::Gaia)
            return false unless Legion::Gaia.respond_to?(:started?) && Legion::Gaia.started?

            !Legion::Gaia.respond_to?(:router_mode?) || !Legion::Gaia.router_mode?
          rescue StandardError => e
            log.debug "gaia_heartbeat_available? check failed: #{e.message}"
            false
          end

          def apply_initial_jitter
            return unless Helpers::Jitter.jitter_enabled?

            offset = Helpers::Jitter.deterministic_jitter(self.class.name.to_s, time)
            sleep(offset) if offset.positive?
          end
        end
      end
    end
  end
end
