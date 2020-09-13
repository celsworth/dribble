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
  def rtorrent_cmd(input)
    data = JSON.parse(input)
    r = Rtorrent.new(settings.rtorrent_host, 5000).call(*data['command'])
    JSON.generate(data: r)
  rescue StandardError => err
    JSON.generate(error: err.message)
  end

  get '/' do
    File.read('./frontend/index.html')
  end

  get '/ws' do
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
      end

      ws.onmessage do |msg|
        # EM.next_tick { settings.sockets.each { |s| s.send(msg) } }
        ws.send(rtorrent_cmd(msg))
      end

      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end
