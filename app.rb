# frozen_string_literal: true

require 'sinatra/reloader'
require 'sassc'
require 'dotenv'
require 'excon'

Dotenv.load

Excon.defaults[:middlewares] << Excon::Middleware::RedirectFollower

begin
  require 'pry'
rescue LoadError
  nil
end

require 'rtorrent'
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
    # use the environment variable verbatim if set,
    # else assume localhost, but cope with running in Docker
    set :rtorrent_host, ENV['RTORRENT'] || (ENV['DOCKER'] ? 'docker-host' : 'localhost')
    set :rtorrent_port, ENV['RTORRENT_PORT'] || 5000

    set :sass, style: :compact
    set :logging, false # done by iodine -v

    register Sinatra::Reloader
  end

  get '/' do
    erb :index, locals: asset_mtimes
  end

  # only used in dev; in release/Dockerfile we create public/style.css
  # that will be served rather than this.
  get '/css/style.css' do
    etag File.mtime('assets/css/style.scss')
    content_type 'text/css'
    scss = File.read('assets/css/style.scss')
    SassC::Engine.new(scss,
                      filename: 'style.scss',
                      style: :compressed,
                      source_map_file: '.',
                      source_map_embed: true,
                      source_map_contents: true).render
  end

  get '/ws' do
    return unless env['rack.upgrade?'] == :websocket

    rtorrent = Rtorrent.new(settings.rtorrent_host, settings.rtorrent_port)
    env['rack.upgrade'] = Websocket.new(rtorrent)
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
    [response.status, response.headers, response.body]
  end

  def proxy_cache_headers(env)
    {
      'Accept' => env['HTTP_ACCEPT'],
      'Accept-Encoding' => env['HTTP_ACCEPT_ENCODING'],
      'If-None-Match' => env['HTTP_IF_NONE_MATCH'],
      'If-Modified-Since' => env['HTTP_IF_MODIFIED_SINCE']
    }
  end

  def asset_mtimes
    style = if File.exist?('public/style.css')
              'public/style.css'
            else
              'assets/css/style.scss'
            end
    style_mtime = File.mtime(style).to_i

    { app_mtime: File.mtime('public/js/app.js').to_i,
      style_mtime: style_mtime,
      dribble_mtime: File.mtime('public/dribble.js').to_i }
  end
end
