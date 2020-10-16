# frozen_string_literal: true

require 'sinatra/reloader'
require 'sassc'

begin
  require 'pry'
rescue LoadError
  nil
end

require 'rtorrent'

require 'subscription'
require 'subscription_runner'
require 'websocket'

# Connects to rtorrent at localhost:5000 by default. eg in rtorrent:
#    network.scgi.open_port = 127.0.0.1:5000
#
# With the default docker-compose which sets ENV['DOCKER'] = true,
# assumes rtorrent is running on the host at port 5000.
#
# To change rtorrent's location, set ENV['RTORRENT'] to the IP or a UNIX path.
# To change the port from 5000, set ENV['RTORRENT_PORT'] (ignored for UNIX paths)

class Dribble < Sinatra::Application
  configure do
    set :sockets, {}

    set :subscription_runner, SubscriptionRunner.new.tap(&:start)

    # use the environment variable verbatim if set,
    # else assume localhost, but cope with running in Docker
    set :rtorrent_host, ENV['RTORRENT'] || (ENV['DOCKER'] ? 'docker-host' : 'localhost')
    set :rtorrent_port, ENV['RTORRENT_PORT'] || 5000

    set :sass, style: :compact

    register Sinatra::Reloader
  end

  get '/' do
    File.read('./frontend/index.html')
  end

  get '/css/style.css' do
    etag File.mtime 'assets/css/style.scss'
    content_type 'text/css'
    scss = File.read('assets/css/style.scss')
    # TODO: save rendered css for future static return;
    # need a filename fingerprint
    SassC::Engine.new(scss, style: :compressed).render
  end

  get '/ws' do
    request.websocket do |ws|
      ws.onopen do
        t = settings.sockets[ws] = Websocket.new(ws)
        settings.subscription_runner.add_websocket(t)
      end

      ws.onmessage do |msg|
        t = settings.sockets[ws]
        process_websocket(t, JSON.parse(msg))
      end

      ws.onclose do
        t = settings.sockets[ws]
        settings.subscription_runner.remove_websocket(t)
      end
    end
  end

  def process_websocket(websocket, data)
    if (u = data['unsubscribe'])
      websocket.remove_subscription(u)
    elsif (s = data['subscribe'])
      rtorrent = Rtorrent.new(settings.rtorrent_host, settings.rtorrent_port)
      sub = Subscription.new(interval: data['interval'],
                             rtorrent: rtorrent,
                             diff: data['diff'],
                             command: data['command'])
      websocket.add_subscription(s, sub)
      # immediately run all due subscriptions for this websocket when a new one
      # is added. This reduces delay between selecting a torrent and seeing file
      # list for it.
      websocket.run_subscriptions
    else
      # TODO: move this into a class?
      rtorrent = Rtorrent.new(settings.rtorrent_host, settings.rtorrent_port)
      websocket.send(data['name'] => rtorrent.call(*data['command']))
    end
  end
end
