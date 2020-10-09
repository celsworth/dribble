# frozen_string_literal: true

require 'data_differ'
require 'rtorrent'

# Store details about a subscription from Elm, with the capability to run it
# and return changed data.
#
class Subscription
  attr_reader :diff

  def initialize(command:, diff:, interval:, rtorrent:, data_differ: nil)
    @command = command
    @diff = diff
    @interval = interval

    @rtorrent = rtorrent

    @data_differ = (data_differ || DataDiffer.new) if @diff
  end

  def due?
    @last_run.nil? || Time.now - @last_run > @interval
  end

  def run
    @last_run = Time.now
    data = @rtorrent.call(*@command)
    @diff ? @data_differ.diff(data) : data
  end
end
