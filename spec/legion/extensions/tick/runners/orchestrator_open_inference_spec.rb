# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Orchestrator OpenInference instrumentation' do
  let(:host) { Object.new.extend(Legion::Extensions::Tick::Runners::Orchestrator) }

  before do
    stub_const('Legion::Telemetry::OpenInference', Module.new do
      def self.open_inference_enabled?
        true
      end

      def self.agent_span(**)
        yield(nil)
      end
    end)
  end

  describe '#execute_tick' do
    it 'wraps tick execution in agent_span' do
      expect(Legion::Telemetry::OpenInference).to receive(:agent_span)
        .with(hash_including(name: kind_of(String), mode: kind_of(Symbol)))
        .and_yield(nil)

      host.execute_tick(signals: [], phase_handlers: {})
    end

    it 'works without OpenInference loaded' do
      hide_const('Legion::Telemetry::OpenInference')
      result = host.execute_tick(signals: [], phase_handlers: {})
      expect(result[:tick_number]).to eq(1)
    end
  end
end
