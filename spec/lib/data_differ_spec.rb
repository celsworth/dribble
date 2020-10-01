# frozen_string_literal: true

require 'data_differ'

RSpec.describe DataDiffer do
  let(:differ) { described_class.new }

  it 'returns all data on the first run' do
    data = [[1, 1], [2, 2]]
    expect(differ.diff(data)).to eq data
  end

  it 'returns changed data on subsequent runs' do
    data = [[1, 1], [2, 2]]
    differ.diff(data)

    expect(differ.diff(data)).to eq []

    data = [[1, 2], [2, 2]]
    expect(differ.diff(data)).to eq [[1, 2]]
  end
end
