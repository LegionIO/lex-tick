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

    it 'returns all 12 phases for full_active' do
      phases = described_class.phases_for_mode(:full_active)
      expect(phases.size).to eq(13)
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

  it 'defines exactly 12 phases' do
    expect(described_class::PHASES.size).to eq(13)
  end

  it 'defines phase budgets for all active phases' do
    described_class::PHASES.each do |phase|
      expect(described_class::PHASE_BUDGETS).to have_key(phase)
    end
  end

  describe 'MODES' do
    it 'includes dormant_active' do
      expect(described_class::MODES).to include(:dormant_active)
    end

    it 'has exactly 4 modes' do
      expect(described_class::MODES.size).to eq(4)
    end
  end

  describe 'DREAM_PHASES' do
    it 'defines 9 dream phases' do
      expect(described_class::DREAM_PHASES.size).to eq(9)
    end

    it 'includes all expected dream phase symbols' do
      expected = %i[memory_audit association_walk contradiction_resolution
                    identity_entropy_check agenda_formation consolidation_commit
                    knowledge_promotion dream_reflection dream_narration]
      expect(described_class::DREAM_PHASES).to eq(expected)
    end
  end

  describe 'MODE_PHASES' do
    it 'maps dormant_active to the 9 dream phases' do
      expect(described_class::MODE_PHASES[:dormant_active]).to eq(described_class::DREAM_PHASES)
    end
  end

  describe '.tick_budget' do
    it 'returns Float::INFINITY for dormant_active' do
      expect(described_class.tick_budget(:dormant_active)).to eq(Float::INFINITY)
    end
  end

  describe 'dream thresholds' do
    it 'defines DREAM_IDLE_THRESHOLD as 1800' do
      expect(described_class::DREAM_IDLE_THRESHOLD).to eq(1800)
    end

    it 'defines SENTINEL_TO_DREAM_THRESHOLD as 600' do
      expect(described_class::SENTINEL_TO_DREAM_THRESHOLD).to eq(600)
    end
  end
end
