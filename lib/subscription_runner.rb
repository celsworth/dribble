# frozen_string_literal: true

# Maintain a thread to run subscriptions for websocket connections when they become due
class SubscriptionRunner
  def initialize
    # keyed by socket
    @websockets = []
  end

  def start
    run
  rescue StandardError => e
    # thread aborted! restart it
    warn "SubscriptionRunner thread death: #{e.message}"
    warn e.backtrace
    sleep 5

    retry
  end

  def add_websocket(websocket)
    @websockets << websocket
  end

  def remove_websocket(websocket)
    @websockets.delete(websocket)
  end

  private

  def run
    Thread.new do
      loop do
        @websockets.each(&:run_subscriptions)
        sleep 1
      end
    end
  end
end
