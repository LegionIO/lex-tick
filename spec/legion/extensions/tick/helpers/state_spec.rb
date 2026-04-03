# frozen_string_literal: true

RSpec.describe Legion::Extensions::Tick::Helpers::State do
  let(:state) { described_class.new }

  describe '#initialize' do
    it 'starts in dormant mode' do
      expect(state.mode).to eq(:dormant)
    end

    it 'starts with zero tick count' do
      expect(state.tick_count).to eq(0)
    end
  end

  describe '#record_signal' do
    it 'updates last_signal_at' do
      state.record_signal
      expect(state.last_signal_at).not_to be_nil
    end

    it 'updates last_high_salience_at for high salience signals' do
      state.record_signal(salience: 0.8)
      expect(state.last_high_salience_at).not_to be_nil
    end

    it 'does not update last_high_salience_at for low salience' do
      state.record_signal(salience: 0.3)
      expect(state.last_high_salience_at).to be_nil
    end

    it 'updates last_high_salience_at for human direct signals' do
      state.record_signal(salience: 0.3, source_type: :human_direct)
      expect(state.last_high_salience_at).not_to be_nil
    end
  end

  describe '#increment_tick' do
    it 'increments the tick count' do
      state.increment_tick
      expect(state.tick_count).to eq(1)
    end

    it 'clears phase results' do
      state.record_phase(:test, { result: true })
      state.increment_tick
      expect(state.phase_results).to be_empty
    end
  end

  describe '#seconds_since_signal' do
    it 'treats a fresh boot as recently active' do
      expect(state.seconds_since_signal).to eq(0.0)
    end
  end

  describe '#seconds_since_high_salience' do
    it 'treats missing high-salience history as recent, not infinite' do
      expect(state.seconds_since_high_salience).to eq(0.0)
    end
  end

  describe '#transition_to' do
    it 'changes mode' do
      state.transition_to(:sentinel)
      expect(state.mode).to eq(:sentinel)
    end

    it 'tracks mode history' do
      state.transition_to(:sentinel)
      state.transition_to(:full_active)
      expect(state.mode_history.size).to eq(3) # initial + 2 transitions
    end

    it 'does not add duplicate entries for same mode' do
      state.transition_to(:dormant) # already dormant
      expect(state.mode_history.size).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns state as hash' do
      h = state.to_h
      expect(h).to have_key(:mode)
      expect(h).to have_key(:tick_count)
      expect(h).to have_key(:phases_completed)
    end
  end
end
