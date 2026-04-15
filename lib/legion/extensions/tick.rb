# frozen_string_literal: true

require 'legion/extensions/tick/version'
require 'legion/extensions/tick/helpers/constants'
require 'legion/extensions/tick/helpers/jitter'
require 'legion/extensions/tick/helpers/state'
require 'legion/extensions/tick/runners/orchestrator'

module Legion
  module Extensions
    module Tick
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false

      def self.remote_invocable?
        false
      end

      def self.mcp_tools?
        false
      end

      def self.mcp_tools_deferred?
        false
      end

      def self.transport_required?
        false
      end
    end
  end
end
