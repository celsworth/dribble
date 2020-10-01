# frozen_string_literal: true

require 'pathname'

RSpec.configure do |c|
  c.filter_run :focus
  c.run_all_when_everything_filtered = true

  c.order = :random
  Kernel.srand c.seed
end
