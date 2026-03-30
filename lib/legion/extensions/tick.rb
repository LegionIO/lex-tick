# frozen_string_literal: true

require 'legion/extensions/tick/version'
require 'legion/extensions/tick/helpers/constants'
require 'legion/extensions/tick/helpers/state'
require 'legion/extensions/tick/runners/orchestrator'

module Legion
  module Extensions
    module Tick
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false

      def self.remote_invocable?
        false
      end
    end
  end
end
