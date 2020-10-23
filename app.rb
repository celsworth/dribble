# frozen_string_literal: true

require 'sinatra/reloader'
require 'sassc'
require 'excon'

Excon.defaults[:middlewares] << Excon::Middleware::RedirectFollower

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

  # GET /proxy/foo.url/favicon.ico
  #
  # This is used by Elm to get favicons through us. It's not strictly necessary,
  # Elm could render an <img> tag and fetch directly, but I found a few icons failed
  # because a Referrer was set by the browser and some sites didn't like that.
  # Plus, in future we could cache here to avoid hitting the sites too often.
  # We pass along a load of headers to try quite hard to make caches work,
  # and enforce some quite lax headers in the response as these don't change much.
  get '/proxy/*' do |url|
    response = Excon.get("http://#{url}", headers: proxy_cache_headers(request.env))
    response.headers['Expires'] = [Time.now + 604_800]
    response.headers['Cache-Control'] = ['public']
    [response.status, response.headers, StringIO.new(response.body)]
  end

  def proxy_cache_headers(env)
    {
      'Accept' => env['HTTP_ACCEPT'],
      'Accept-Encoding' => env['HTTP_ACCEPT_ENCODING'],
      'If-None-Match' => env['HTTP_IF_NONE_MATCH'],
      'If-Modified-Since' => env['HTTP_IF_MODIFIED_SINCE']
    }
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
