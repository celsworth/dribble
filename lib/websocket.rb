# frozen_string_literal: true

require 'json'

# Details about a connected websocket and their subscriptions
class Websocket
  def initialize(socket)
    @socket = socket
    @subscriptions = {}
  end

  def add_subscription(name, subscription)
    @subscriptions[name] = subscription
  end

  def remove_subscription(name)
    @subscriptions.delete(name)
  end

  def run_subscriptions
    @subscriptions.each do |name, subscription|
      next unless subscription.due?

      data = run_handling_error(name, subscription)

      send(data) if data
    end
  end

  def send(data)
    @socket.send(JSON.generate(data))
  end

  private

  def run_handling_error(name, subscription)
    data = subscription.run
    { name => data } unless data.empty? && subscription.diff
  rescue StandardError => e
    { error: e.message }
  end
end
