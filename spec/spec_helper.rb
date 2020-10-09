# frozen_string_literal: true

require 'pathname'

RSpec.configure do |c|
  c.filter_run :focus
  c.run_all_when_everything_filtered = true

  c.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  c.order = :random
  Kernel.srand c.seed
end
