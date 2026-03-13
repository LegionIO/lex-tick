# frozen_string_literal: true

require 'legion/extensions/tick/helpers/constants'
require 'legion/extensions/tick/helpers/state'
require 'legion/extensions/tick/runners/orchestrator'

module Legion
  module Extensions
    module Tick
      class Client
        include Runners::Orchestrator

        def initialize(mode: :dormant, **)
          @tick_state = Helpers::State.new(mode: mode)
        end

        private

        attr_reader :tick_state
      end
    end
  end
end
