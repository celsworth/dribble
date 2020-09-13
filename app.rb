# frozen_string_literal: true

require 'sinatra/reloader'

$LOAD_PATH.unshift 'lib'
require 'rtorrent'

class Dribble < Sinatra::Base
  set :server, 'thin'
  set :sockets, []

  set :rtorrent_host, ENV['DOCKER'] ? 'docker-host' : 'localhost'

  configure do
    register Sinatra::Reloader
  end

  def get_hashes
    Rtorrent.new(settings.rtorrent_host, 5000)
            .call('d.multicall2', '', 'main', 'd.hash=', 'd.name=')
            .map do |arr|
              { hash: arr[0], name: arr[1], test: 1 }
            end
  end

  # Given some input from our WebSocket, parse it and work out what to do
  def parse_ws(input)
    json = JSON.parse(input)
  end

  get '/' do
    File.read('./frontend/index.html')
  end

  get '/ws' do
    request.websocket do |ws|
      ws.onopen do
        # to send torrent list immediately on open..
        # probably not going this way, want elm to request it explictly
        # ws.send(JSON.generate(data: { torrents: get_hashes }))
        settings.sockets << ws
      end

      ws.onmessage do |msg|
        # EM.next_tick { settings.sockets.each { |s| s.send(msg) } }
        ws.send(JSON.generate(data: { torrents: get_hashes }))
      end

      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end
