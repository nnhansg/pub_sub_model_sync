# frozen_string_literal: true

RSpec.describe PubSubModelSync::MessageProcessor do
  let(:subs_klass) { PubSubModelSync::Subscriber }
  let(:klass) { 'SampleUser' }
  let(:action) { :create }
  let(:data) { { title: 'title' } }

  describe 'class message' do
    let(:inst) { described_class.new(data, klass, action) }
    let(:subscriber) do
      subs_klass.new(klass, action, settings: { direct_mode: true })
    end

    describe 'subscriber exists' do
      it 'normal subscriber' do
        stub_subscriber(subscriber) do
          expect(inst).to receive(:run_subscriber).with(subscriber)
          inst.process
        end
      end

      it 'subscriber with custom klass' do
        custom_klass = 'CustomClass'
        subscriber.settings[:as_klass] = custom_klass
        inst.klass = custom_klass
        stub_subscriber(subscriber) do
          expect(inst).to receive(:run_subscriber).with(subscriber)
          inst.process
        end
      end

      it 'subscriber with custom action' do
        custom_method = :custom_method
        subscriber.settings[:as_action] = custom_method
        inst.action = custom_method
        stub_subscriber(subscriber) do
          expect(inst).to receive(:run_subscriber).with(subscriber)
          inst.process
        end
      end
    end

    it 'no subscriber found: different klass' do
      inst.klass = :UnknownClass
      stub_subscriber(subscriber) do
        expect(inst).not_to receive(:run_subscriber).with(subscriber)
        inst.process
      end
    end

    it 'no subscriber found: different action' do
      inst.action = :unknown_action
      stub_subscriber(subscriber) do
        expect(inst).not_to receive(:run_subscriber).with(subscriber)
        inst.process
      end
    end

    it 'print error if failed' do
      error_msg = 'Error message'
      allow(inst).to receive(:log)
      stub_subscriber(subscriber) do
        allow(subscriber).to receive(:eval_message).and_raise(error_msg)
        expect(inst).to receive(:log).with(/#{error_msg}/, anything)
        inst.process
      end
    end
  end

  describe 'model message' do
    let(:inst) { described_class.new(data, klass, action) }
    let(:attrs) { %i[title] }
    let(:subscriber) do
      settings = { direct_mode: false }
      subs_klass.new(klass, action, attrs: attrs, settings: settings)
    end

    it 'existent subscriber' do
      stub_subscriber(subscriber) do
        expect(inst).to receive(:run_subscriber).with(subscriber)
        inst.process
      end
    end

    it 'no subscriber found: different action' do
      inst.action = :unknown_action
      stub_subscriber(subscriber) do
        expect(inst).not_to receive(:run_subscriber).with(subscriber)
        inst.process
      end
    end

    it 'no subscriber found: different klass' do
      inst.klass = :UnknownClass
      stub_subscriber(subscriber) do
        expect(inst).not_to receive(:run_subscriber).with(subscriber)
        inst.process
      end
    end
  end
end
