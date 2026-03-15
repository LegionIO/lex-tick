# frozen_string_literal: true

# Stub the framework actor base class since legionio gem is not available in test
module Legion
  module Extensions
    module Actors
      class Every # rubocop:disable Lint/EmptyClass
      end
    end
  end
end

# Intercept the require in the actor file so it doesn't fail
$LOADED_FEATURES << 'legion/extensions/actors/every'

require 'legion/extensions/tick/actors/tick'

RSpec.describe Legion::Extensions::Tick::Actor::Tick do
  subject(:actor) { described_class.new }

  describe '#initialize' do
    context 'when Cortex is NOT defined' do
      before { hide_const('Legion::Extensions::Cortex') }

      it 'instantiates without error' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context 'when Cortex IS defined' do
      before { stub_const('Legion::Extensions::Cortex', Module.new) }

      it 'instantiates without error (returns early, skips super)' do
        expect { described_class.new }.not_to raise_error
      end
    end
  end

  describe '#enabled?' do
    context 'when Cortex is NOT defined' do
      before { hide_const('Legion::Extensions::Cortex') }

      it 'returns truthy' do
        expect(actor.enabled?).to be_truthy
      end
    end

    context 'when Cortex IS defined' do
      before { stub_const('Legion::Extensions::Cortex', Module.new) }

      it 'returns falsey' do
        expect(actor.enabled?).to be_falsey
      end
    end
  end

  describe '#runner_class' do
    it 'returns the Orchestrator module' do
      expect(actor.runner_class).to eq(Legion::Extensions::Tick::Runners::Orchestrator)
    end
  end

  describe '#runner_function' do
    it 'returns execute_tick' do
      expect(actor.runner_function).to eq('execute_tick')
    end
  end

  describe '#time' do
    it 'returns 1' do
      expect(actor.time).to eq(1)
    end
  end

  describe '#run_now?' do
    it 'returns true' do
      expect(actor.run_now?).to be true
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(actor.use_runner?).to be false
    end
  end

  describe '#check_subtask?' do
    it 'returns false' do
      expect(actor.check_subtask?).to be false
    end
  end

  describe '#generate_task?' do
    it 'returns false' do
      expect(actor.generate_task?).to be false
    end
  end

  describe '#args' do
    it 'returns a hash with empty signals and phase_handlers' do
      expect(actor.args).to eq({ signals: [], phase_handlers: {} })
    end
  end
end
