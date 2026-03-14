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

            super
          end

          def runner_class
            Legion::Extensions::Tick::Runners::Orchestrator
          end

          def runner_function
            'execute_tick'
          end

          def enabled?
            !Legion::Extensions.const_defined?(:Cortex)
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
            { signals: [], phase_handlers: {} }
          end
        end
      end
    end
  end
end
