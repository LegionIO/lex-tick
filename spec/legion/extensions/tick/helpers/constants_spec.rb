# frozen_string_literal: true

RSpec.describe Legion::Extensions::Tick::Helpers::Constants do
  describe '.phases_for_mode' do
    it 'returns 1 phase for dormant' do
      phases = described_class.phases_for_mode(:dormant)
      expect(phases).to eq([:memory_consolidation])
    end

    it 'returns 5 phases for sentinel' do
      phases = described_class.phases_for_mode(:sentinel)
      expect(phases.size).to eq(5)
      expect(phases).to include(:sensory_processing, :memory_retrieval)
    end

    it 'returns all 11 phases for full_active' do
      phases = described_class.phases_for_mode(:full_active)
      expect(phases.size).to eq(11)
    end
  end

  describe '.tick_budget' do
    it 'returns 0.2s for dormant' do
      expect(described_class.tick_budget(:dormant)).to eq(0.2)
    end

    it 'returns 0.5s for sentinel' do
      expect(described_class.tick_budget(:sentinel)).to eq(0.5)
    end

    it 'returns 5.0s for full_active' do
      expect(described_class.tick_budget(:full_active)).to eq(5.0)
    end
  end

  it 'defines exactly 11 phases' do
    expect(described_class::PHASES.size).to eq(11)
  end

  it 'defines phase budgets summing to 1.0' do
    total = described_class::PHASE_BUDGETS.values.sum
    expect(total).to be_within(0.001).of(1.0)
  end
end
