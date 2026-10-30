# frozen_string_literal: true

require 'legion/extensions/tick/client'

RSpec.describe Legion::Extensions::Tick::Runners::Orchestrator do
  let(:client) { Legion::Extensions::Tick::Client.new }

  describe '.remote_invocable?' do
    it 'returns false to prevent remote dispatch' do
      expect(described_class.remote_invocable?).to be false
    end
  end

  describe '#execute_tick' do
    let(:dream_handlers) do
      Legion::Extensions::Tick::Helpers::Constants::DREAM_PHASES.to_h { |phase| [phase, ->(**) { { status: :ok } }] }
    end

    before do
      allow(client.send(:tick_state)).to receive(:seconds_since_signal).and_return(60.0)
    end

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

    it 'reports no_handler for unhandled phases' do
      result = client.execute_tick
      expect(result[:results][:memory_consolidation][:status]).to eq(:no_handler)
    end

    it 'promotes to sentinel on incoming signals' do
      client.execute_tick(signals: [{ salience: 0.3 }])
      result = client.execute_tick(signals: [{ salience: 0.3 }])
      expect(result[:mode]).to eq(:sentinel)
    end

    it 'runs action selection for the first human signal without a second signal' do
      result = client.execute_tick(
        signals:        [{ source_type: :human_direct, salience: 0.1 }],
        phase_handlers: { action_selection: ->(**) { { status: :selected } } }
      )

      expect(result[:mode]).to eq(:full_active)
      expect(result[:results][:action_selection]).to eq(status: :selected)
      expect(client.execute_tick[:mode]).to eq(:full_active)
    end

    it 'promotes a dormant agent immediately for a high-salience non-human signal' do
      result = client.execute_tick(signals: [{ source_type: :sensor, salience: 0.9 }])

      expect(result[:mode]).to eq(:full_active)
      expect(result[:phases_executed]).to include(:action_selection)
    end

    it 'interrupts a dream with full processing for a low-salience human signal' do
      dreaming_client = Legion::Extensions::Tick::Client.new(mode: :dormant_active)
      result = dreaming_client.execute_tick(signals: [{ source_type: :human_direct, salience: 0.1 }])

      expect(result[:mode]).to eq(:full_active)
      expect(result[:phases_executed]).to include(:action_selection)
      expect(result[:phases_executed]).not_to include(:dream_narration)
      expect(dreaming_client.tick_status[:last_dream_completed_at]).to be_nil
    end

    it 'honors a forced mode for one tick before allowing human promotion' do
      client.set_mode(mode: :sentinel)
      signals = [{ source_type: :human_direct, salience: 0.1 }]

      expect(client.execute_tick(signals: signals)[:phases_executed]).not_to include(:action_selection)
      expect(client.execute_tick(signals: signals)[:phases_executed]).to include(:action_selection)
    end

    it 'completes one dormant_active dream cycle and backs off to dormant' do
      client.set_mode(mode: :dormant_active)

      result = client.execute_tick(phase_handlers: dream_handlers)

      expect(result[:phases_executed]).to eq(Legion::Extensions::Tick::Helpers::Constants::DREAM_PHASES)
      expect(result[:mode]).to eq(:dormant)
      expect(client.tick_status[:last_dream_completed_at]).not_to be_nil
    end

    it 'does not immediately restart a completed dream cycle on the next heartbeat' do
      state = client.send(:tick_state)
      allow(state).to receive(:seconds_since_signal).and_return(1801.0)

      client.set_mode(mode: :dormant_active)
      client.execute_tick(phase_handlers: dream_handlers)
      result = client.execute_tick

      expect(result[:mode]).to eq(:dormant)
      expect(result[:phases_executed]).to eq([:memory_consolidation])
    end

    it 'backs off to dormant when a dream phase fails' do
      client.set_mode(mode: :dormant_active)

      result = client.execute_tick(
        phase_handlers: dream_handlers.merge(dream_narration: ->(**) { { status: :error } })
      )

      expect(result[:mode]).to eq(:dormant)
      expect(result[:results][:dream_narration][:status]).to eq(:error)
      expect(client.tick_status[:last_dream_completed_at]).to be_nil
      expect(client.tick_status[:last_dream_deferred_at]).not_to be_nil
    end

    it 'backs off to dormant when the dream tick budget is exhausted before all phases run' do
      constants = Legion::Extensions::Tick::Helpers::Constants
      allow(constants).to receive(:tick_budget).and_call_original
      allow(constants).to receive(:tick_budget).with(:dormant_active).and_return(0.0)

      client.set_mode(mode: :dormant_active)
      result = client.execute_tick

      expect(result[:mode]).to eq(:dormant)
      expect(result[:phases_executed]).to be_empty
      expect(result[:phases_skipped]).to eq(constants::DREAM_PHASES)
      expect(client.tick_status[:last_dream_completed_at]).to be_nil
      expect(client.tick_status[:last_dream_deferred_at]).not_to be_nil
    end

    it 'backs off an unhandled dream without claiming completion' do
      state = client.send(:tick_state)
      allow(state).to receive(:seconds_since_signal).and_return(1801.0)
      client.set_mode(mode: :dormant_active)

      client.execute_tick
      expect(client.tick_status[:last_dream_completed_at]).to be_nil
      expect(client.execute_tick[:phases_executed]).to eq([:memory_consolidation])
    end

    it 'does not claim completion when a handler reports unsuccessful work without a status' do
      client.set_mode(mode: :dormant_active)
      client.execute_tick(phase_handlers: dream_handlers.merge(dream_narration: ->(**) { { success: false } }))

      expect(client.tick_status[:last_dream_completed_at]).to be_nil
      expect(client.tick_status[:last_dream_deferred_at]).not_to be_nil
    end

    it 'does not immediately replay earlier dream effects when a later handler raises' do
      allow(client.send(:tick_state)).to receive(:seconds_since_signal).and_return(1801.0)
      effects = []
      handlers = dream_handlers.merge(
        memory_audit:     ->(**) { effects << :audit },
        association_walk: ->(**) { raise 'association failure' }
      )
      client.set_mode(mode: :dormant_active)

      expect { client.execute_tick(phase_handlers: handlers) }.to raise_error('association failure')
      expect(client.tick_status[:last_dream_completed_at]).to be_nil
      client.execute_tick(phase_handlers: handlers)
      expect(effects).to eq([:audit])
    end

    it 'keeps budget accounting independent of backwards wall-clock adjustments' do
      allow(Time).to receive(:now).and_return(Time.utc(2026, 10, 29))
      result = client.execute_tick(phase_handlers: {
                                     memory_consolidation: lambda { |**|
                                       allow(Time).to receive(:now).and_return(Time.utc(2026, 10, 28))
                                       { status: :ok }
                                     }
                                   })

      expect(result[:elapsed]).to be >= 0.0
      expect(result[:elapsed]).to be < 1.0
    end
  end

  describe '#evaluate_mode_transition' do
    it 'promotes dormant to sentinel on a low-salience non-human signal' do
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

    it 'does not transition without trigger when recently active' do
      state = client.send(:tick_state)
      allow(state).to receive(:seconds_since_signal).and_return(60.0)
      result = client.evaluate_mode_transition
      expect(result[:transitioned]).to be false
    end

    it 'does not enter dormant_active immediately on fresh boot' do
      result = client.evaluate_mode_transition
      expect(result[:transitioned]).to be false
      expect(result[:current_mode]).to eq(:dormant)
    end

    context 'dormant_active transitions' do
      it 'transitions dormant -> dormant_active after DREAM_IDLE_THRESHOLD with no signals' do
        state = client.send(:tick_state)
        allow(state).to receive(:seconds_since_signal).and_return(1801.0)
        result = client.evaluate_mode_transition
        expect(result[:transitioned]).to be true
        expect(result[:new_mode]).to eq(:dormant_active)
      end

      it 'transitions dormant -> sentinel when signals arrive (not dormant_active)' do
        state = client.send(:tick_state)
        allow(state).to receive(:seconds_since_signal).and_return(1801.0)
        result = client.evaluate_mode_transition(signals: [{ salience: 0.3 }])
        expect(result[:transitioned]).to be true
        expect(result[:new_mode]).to eq(:sentinel)
      end

      it 'transitions dormant_active -> full_active on high-salience signal' do
        client.set_mode(mode: :dormant_active)
        result = client.evaluate_mode_transition(signals: [{ salience: 0.9 }])
        expect(result[:transitioned]).to be true
        expect(result[:new_mode]).to eq(:full_active)
      end

      it 'transitions dormant_active -> dormant when dream_complete: true with no signals' do
        client.set_mode(mode: :dormant_active)
        result = client.evaluate_mode_transition(dream_complete: true)
        expect(result[:transitioned]).to be true
        expect(result[:new_mode]).to eq(:dormant)
        expect(client.tick_status[:last_dream_completed_at]).not_to be_nil
      end

      it 'stays dormant_active when no signals and dream not complete' do
        client.set_mode(mode: :dormant_active)
        result = client.evaluate_mode_transition
        expect(result[:transitioned]).to be false
        expect(result[:current_mode]).to eq(:dormant_active)
      end

      it 'keeps dormant backed off after a completed dream cycle' do
        state = client.send(:tick_state)
        state.record_dream_completed
        allow(state).to receive(:seconds_since_signal).and_return(1801.0)

        result = client.evaluate_mode_transition

        expect(result[:transitioned]).to be false
        expect(result[:current_mode]).to eq(:dormant)
      end

      it 'allows dormant_active again after dream backoff elapses' do
        state = client.send(:tick_state)
        state.record_dream_completed
        allow(state).to receive(:seconds_since_signal).and_return(1801.0)
        allow(state).to receive(:seconds_since_dream_completed).and_return(1801.0)

        result = client.evaluate_mode_transition

        expect(result[:transitioned]).to be true
        expect(result[:new_mode]).to eq(:dormant_active)
      end
    end

    context 'sentinel -> dormant_active' do
      it 'transitions sentinel -> dormant_active after SENTINEL_TO_DREAM_THRESHOLD with no signals' do
        client.set_mode(mode: :sentinel)
        state = client.send(:tick_state)
        allow(state).to receive(:seconds_since_signal).and_return(601.0)
        result = client.evaluate_mode_transition
        expect(result[:transitioned]).to be true
        expect(result[:new_mode]).to eq(:dormant_active)
      end
    end

    context 'full_active cooldown' do
      it 'demotes full_active after ACTIVE_TIMEOUT when only human-direct signal history exists' do
        client.set_mode(mode: :full_active)
        state = client.send(:tick_state)
        allow(state).to receive(:last_high_salience_at).and_return(nil)
        allow(state).to receive(:last_signal_at).and_return(Time.now.utc - 301)
        allow(state).to receive(:seconds_since_signal).and_return(301.0)

        result = client.evaluate_mode_transition

        expect(result[:transitioned]).to be true
        expect(result[:new_mode]).to eq(:sentinel)
      end
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
