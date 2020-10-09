# frozen_string_literal: true

require 'subscription'

RSpec.describe Subscription do
  let(:subscription) do
    described_class.new(command: command, diff: diff,
                        interval: interval, rtorrent: rtorrent)
  end

  let(:command) { ['d.multicall2', '', 'main', 'd.hash=', 'd.name='] }
  let(:interval) { 5 }
  let(:rtorrent) { instance_double(Rtorrent) }
  let(:diff) { false }

  it 'is initially due' do
    expect(subscription).to be_due
  end

  it 'is not due immediately after a run' do
    expect(rtorrent).to receive(:call)
    subscription.run

    expect(subscription).not_to be_due
  end

  it 'is not due before the desired interval' do
    expect(rtorrent).to receive(:call)
    subscription.run

    expect(Time).to receive(:now).and_return(Time.now + 2)
    expect(subscription).not_to be_due
  end

  it 'is due after the desired interval' do
    expect(rtorrent).to receive(:call)
    subscription.run

    expect(Time).to receive(:now).and_return(Time.now + 5)
    expect(subscription).to be_due
  end

  it 'splats arguments to rtorrent' do
    expect(rtorrent)
      .to receive(:call)
      .with('d.multicall2', '', 'main', 'd.hash=', 'd.name=')
    subscription.run
  end

  it 'returns complete data' do
    expect(rtorrent).to receive(:call).and_return([[1, 1], [2, 2]])
    expect(rtorrent).to receive(:call).and_return([[1, 1], [2, 1]])

    expect(subscription.run).to eq [[1, 1], [2, 2]]
    expect(subscription.run).to eq [[1, 1], [2, 1]]
  end

  context 'diff: true' do
    let(:diff) { true }
    it 'returns diffed data' do
      expect(rtorrent).to receive(:call).and_return([[1, 1], [2, 2]])
      expect(rtorrent).to receive(:call).and_return([[1, 1], [2, 1]])

      expect(subscription.run).to eq [[1, 1], [2, 2]]
      expect(subscription.run).to eq [[2, 1]]
    end
  end
end
