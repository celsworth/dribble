# frozen_string_literal: true

require 'sinatra/reloader'

require 'rtorrent'

class Dribble < Sinatra::Application
  configure do
    set :sockets, []
    set :rtorrent_host, ENV['DOCKER'] ? 'docker-host' : 'localhost'

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
  rescue StandardError => e
    JSON.generate(error: e.message)
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
