# frozen_string_literal: true

require 'legion/extensions/tick/client'

RSpec.describe Legion::Extensions::Tick::Runners::Orchestrator do
  let(:client) { Legion::Extensions::Tick::Client.new }

  describe '#execute_tick' do
    it 'executes phases for current mode' do
      result = client.execute_tick
      expect(result[:mode]).to eq(:dormant)
      expect(result[:phases_executed]).to include(:memory_consolidation)
    end

    it 'increments tick number' do
      r1 = client.execute_tick
      r2 = client.execute_tick
      expect(r2[:tick_number]).to eq(r1[:tick_number] + 1)
    end

    it 'uses phase handlers when provided' do
      handler_called = false
      handlers = {
        memory_consolidation: lambda { |**|
          handler_called = true
          { status: :ok }
        }
      }
      client.execute_tick(phase_handlers: handlers)
      expect(handler_called).to be true
    end

    it 'reports no_handler for unhandled phases' do
      result = client.execute_tick
      expect(result[:results][:memory_consolidation][:status]).to eq(:no_handler)
    end

    it 'promotes to sentinel on incoming signals' do
      client.execute_tick(signals: [{ salience: 0.3 }])
      result = client.execute_tick(signals: [{ salience: 0.3 }])
      expect(result[:mode]).to eq(:sentinel)
    end
  end

  describe '#evaluate_mode_transition' do
    it 'promotes dormant to sentinel on any signal' do
      result = client.evaluate_mode_transition(signals: [{ salience: 0.1 }])
      expect(result[:transitioned]).to be true
      expect(result[:new_mode]).to eq(:sentinel)
    end

    it 'promotes sentinel to full_active on high salience' do
      client.set_mode(mode: :sentinel)
      result = client.evaluate_mode_transition(signals: [{ salience: 0.9 }])
      expect(result[:transitioned]).to be true
      expect(result[:new_mode]).to eq(:full_active)
    end

    it 'promotes sentinel to full_active on human interaction' do
      client.set_mode(mode: :sentinel)
      result = client.evaluate_mode_transition(signals: [{ source_type: :human_direct, salience: 0.3 }])
      expect(result[:transitioned]).to be true
      expect(result[:new_mode]).to eq(:full_active)
    end

    it 'promotes to full_active on emergency' do
      result = client.evaluate_mode_transition(emergency: :firmware_violation)
      expect(result[:transitioned]).to be true
      expect(result[:new_mode]).to eq(:full_active)
    end

    it 'does not transition without trigger' do
      result = client.evaluate_mode_transition
      expect(result[:transitioned]).to be false
    end
  end

  describe '#set_mode' do
    it 'sets valid mode' do
      result = client.set_mode(mode: :full_active)
      expect(result[:mode]).to eq(:full_active)
    end

    it 'rejects invalid mode' do
      result = client.set_mode(mode: :invalid)
      expect(result[:error]).to eq(:invalid_mode)
    end
  end

  describe '#tick_status' do
    it 'returns current state' do
      status = client.tick_status
      expect(status[:mode]).to eq(:dormant)
      expect(status[:tick_count]).to eq(0)
    end
  end
end
