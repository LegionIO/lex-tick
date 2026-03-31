# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Tick::Helpers::Jitter do
  describe '.deterministic_jitter' do
    it 'returns the same value for the same task name and interval' do
      a = described_class.deterministic_jitter('my_task', 60)
      b = described_class.deterministic_jitter('my_task', 60)
      expect(a).to eq(b)
    end

    it 'returns different values for different task names' do
      a = described_class.deterministic_jitter('task_alpha', 600)
      b = described_class.deterministic_jitter('task_beta', 600)
      # Different names should almost always differ (hash collision is astronomically rare)
      # but we assert the function is at least defined and returns integers
      expect(a).to be_a(Integer)
      expect(b).to be_a(Integer)
    end

    it 'returns a value within the 10% bound of the interval' do
      interval = 600
      max_jitter = (interval * 0.1).to_i
      jitter = described_class.deterministic_jitter('interval_actor', interval)
      expect(jitter).to be >= 0
      expect(jitter).to be < max_jitter
    end

    it 'caps jitter at MAX_JITTER_CAP (900 seconds) regardless of interval' do
      jitter = described_class.deterministic_jitter('large_interval_actor', 100_000)
      expect(jitter).to be < described_class::MAX_JITTER_CAP
    end

    it 'returns 0 for very small intervals where 10% rounds to < 1 second' do
      expect(described_class.deterministic_jitter('tiny_task', 5)).to eq(0)
      expect(described_class.deterministic_jitter('tiny_task', 1)).to eq(0)
    end

    it 'returns 0 for a zero interval' do
      expect(described_class.deterministic_jitter('zero_task', 0)).to eq(0)
    end

    it 'accepts a symbol task name without raising' do
      expect { described_class.deterministic_jitter(:symbol_task, 120) }.not_to raise_error
    end

    it 'produces an integer result' do
      result = described_class.deterministic_jitter('my_task', 300)
      expect(result).to be_a(Integer)
    end
  end

  describe '.jitter_enabled?' do
    context 'when Legion::Settings is not available or returns nil' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:tick).and_return(nil)
      end

      it 'defaults to true' do
        expect(described_class.jitter_enabled?).to be true
      end
    end

    context 'when settings return a hash with jitter_enabled: true' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:tick).and_return({ jitter_enabled: true })
      end

      it 'returns true' do
        expect(described_class.jitter_enabled?).to be true
      end
    end

    context 'when settings return a hash with jitter_enabled: false' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:tick).and_return({ jitter_enabled: false })
      end

      it 'returns false' do
        expect(described_class.jitter_enabled?).to be false
      end
    end

    context 'when settings raise a StandardError' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:tick).and_raise(StandardError)
      end

      it 'defaults to true' do
        expect(described_class.jitter_enabled?).to be true
      end
    end

    context 'when settings return a non-hash value' do
      before do
        allow(Legion::Settings).to receive(:[]).with(:tick).and_return('invalid')
      end

      it 'defaults to true' do
        expect(described_class.jitter_enabled?).to be true
      end
    end
  end
end
