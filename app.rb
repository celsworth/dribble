# frozen_string_literal: true

require 'sinatra/reloader'
require 'sassc'

require 'rtorrent'

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

    # use the environment variable verbatim if set,
    # else assume localhost, but cope with running in Docker
    set :rtorrent_host, ENV['RTORRENT'] || (ENV['DOCKER'] ? 'docker-host' : 'localhost')
    set :rtorrent_port, ENV['RTORRENT_PORT'] || 5000

    set :sass, style: :compact

    register Sinatra::Reloader
  end

  # Given some input from our WebSocket, parse it and work out what to do
  #
  # This is just a simple mapping from JSON to an RPC call:
  #
  # {
  #   command: [
  #     'd.multicall2', '', 'main', 'd.hash=', 'd.name='
  #   ]
  # }
  #
  # For the saved command and diffing stuff to work, d.hash must be the first arg.
  #
  def rtorrent_cmd(input, store:)
    rtorrent = Rtorrent.new(settings.rtorrent_host, settings.rtorrent_port)

    key = input['load'] || input['save']
    command = input['command'] || (key && store[key][:command])

    return { error: 'no command, what to do?' } unless command

    data = rtorrent.call(*command)

    new = if input['load']
            diff_arrays(store[key][:data], data)
          else
            data
          end

    store[key] = { command: command, data: data } if key

    { data: new }
  rescue StandardError => e
    { error: e.message }
  end

  # Given last and current are in format:
  # [[hash1, name1], [hash2, name2]] and [[hash1, name1], [hash2, newname2]]
  #
  # Compare them keyed by hash, and return the members that have changed in current
  # => [[hash2, newname2]]
  #
  def diff_arrays(last, current)
    # bit of an assumption that hash is the first array value here..
    l_hash = last.map { |l| [l[0], l] }.to_h
    c_hash = current.map { |c| [c[0], c] }.to_h

    c_hash.reject { |hash, c| c == l_hash[hash] }.values
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
        settings.sockets[ws] = { commands: {} }
      end

      ws.onmessage do |msg|
        # EM.next_tick { settings.sockets.each { |s| s.send(msg) } }

        r = rtorrent_cmd(JSON.parse(msg), store: settings.sockets[ws])
        ws.send(JSON.generate(r))
      end

      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end
