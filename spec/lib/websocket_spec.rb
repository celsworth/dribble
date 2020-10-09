# frozen_string_literal: true

require 'websocket'
require 'sinatra-websocket'

RSpec.describe Websocket do
  let(:websocket) do
    described_class.new(socket)
  end

  let(:socket) { instance_double(SinatraWebsocket::Connection) }

  it 'allows addition and removal of subscriptions' do
    subscription = instance_double(Subscription)

    websocket.add_subscription('test', subscription)
    websocket.remove_subscription('test')

    websocket.run_subscriptions # should do nothing, no stubs on subscription
  end

  it 'does not call run if a subscription is not due' do
    subscription = instance_double(Subscription, due?: false) # run not defined
    websocket.add_subscription('test', subscription)

    websocket.run_subscriptions
  end

  it 'sends the result of run when no data changes' do
    subscription = instance_double(Subscription, run: [], due?: true, diff: false)
    websocket.add_subscription('test', subscription)

    expect(socket).to receive(:send).with('{"test":[]}')
    websocket.run_subscriptions
  end

  context 'on a diff subscription' do
    it 'does not send anything when no data changes' do
      subscription = instance_double(Subscription, run: [], due?: true, diff: true)
      websocket.add_subscription('test', subscription)

      expect(socket).not_to receive(:send)
      websocket.run_subscriptions
    end

    it 'sends the result of run when data changes' do
      subscription = instance_double(Subscription, run: [1], due?: true, diff: true)
      websocket.add_subscription('test', subscription)

      expect(socket).to receive(:send).with('{"test":[1]}')
      websocket.run_subscriptions
    end
  end
end
