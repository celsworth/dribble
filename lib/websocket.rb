# frozen_string_literal: true

require 'json'

class Websocket
  def initialize(rtorrent)
    @rtorrent = rtorrent
    @subscriptions = {}
    @mutex = Mutex.new
  end

  def on_open(client)
    @subscription_runner = Thread.new do
      loop do
        run_subscriptions
        sleep 1
      end
    end

    @client = client
  end

  def on_message(_client, msg)
    process(JSON.parse(msg))
  end

  def on_close(_client)
    @subscription_runner.terminate.join
  end

  private

  def add_subscription(name, subscription)
    @mutex.synchronize { @subscriptions[name] = subscription }
  end

  def remove_subscription(name)
    @mutex.synchronize { @subscriptions.delete(name) }
  end

  def run_subscriptions
    @mutex.synchronize do
      @subscriptions.each do |name, subscription|
        next unless subscription.due?

        data = run_handling_error(name, subscription)

        write(data) if data
      end
    end
  end

  def process(data)
    if (u = data['unsubscribe'])
      remove_subscription(u)
    elsif (s = data['subscribe'])
      sub = Subscription.new(interval: data['interval'],
                             rtorrent: @rtorrent,
                             diff: data['diff'],
                             command: data['command'])
      add_subscription(s, sub)
      # immediately run all due subscriptions for this websocket when a new one
      # is added. This reduces delay between selecting a torrent and seeing file
      # list for it.
      run_subscriptions
    else
      write(data['name'] => @rtorrent.call(*data['command']))
    end
  end

  def write(data)
    @client.write(JSON.generate(data))
  end

  def run_handling_error(name, subscription)
    data = subscription.run
    { name => data } unless data.empty? && subscription.diff
  rescue StandardError => e
    { error: e.message }
  end
end
