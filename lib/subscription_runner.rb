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
        run
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

  private

  def run
    @websockets.each(&:run_subscriptions)
  rescue StandardError => e
    warn "run_subscripions exception: #{e.message}"
    warn e.backtrace
    sleep 5
  end
end
