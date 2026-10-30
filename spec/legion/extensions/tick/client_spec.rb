# frozen_string_literal: true

require 'open3'
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

  it 'executes standalone without the framework or its test helper supplying logging' do
    script = <<~RUBY
      require 'legion/extensions/tick/client'
      result = Legion::Extensions::Tick::Client.new.execute_tick(
        phase_handlers: { memory_consolidation: ->(**) { { consolidated: true } } }
      )
      abort 'consolidation did not execute' unless result.dig(:results, :memory_consolidation, :consolidated)
      puts 'standalone consolidation completed'
    RUBY
    output, status = Open3.capture2e(RbConfig.ruby, '-Ilib', '-e', script)

    expect(status.success?).to be(true), output
    expect(output).to include('standalone consolidation completed')
  end
end
