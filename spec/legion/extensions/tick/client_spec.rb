# frozen_string_literal: true

require 'legion/extensions/tick/client'

RSpec.describe Legion::Extensions::Tick::Client do
  it 'responds to orchestrator methods' do
    client = described_class.new
    expect(client).to respond_to(:execute_tick)
    expect(client).to respond_to(:evaluate_mode_transition)
    expect(client).to respond_to(:tick_status)
    expect(client).to respond_to(:set_mode)
  end

  it 'accepts initial mode' do
    client = described_class.new(mode: :sentinel)
    expect(client.tick_status[:mode]).to eq(:sentinel)
  end

  it 'runs a full active tick with all 12 phases' do
    client = described_class.new(mode: :full_active)
    result = client.execute_tick(signals: [{ salience: 0.9, source_type: :human_direct }])
    expect(result[:phases_executed].size).to eq(12)
  end
end
