# frozen_string_literal: true

# Maintain a thread to run subscriptions for websocket connections when they become due
class SubscriptionRunner
  def initialize
    # keyed by socket
    @websockets = []
  end

  def start
    Thread.new do
      loop do
        @websockets.each(&:run_subscriptions)
        sleep 1
      end
    end
  end

  def add_websocket(websocket)
    @websockets << websocket
  end

  def remove_websocket(websocket)
    @websockets.delete(websocket)
  end
end
