# frozen_string_literal: true

require 'sinatra/reloader'

class Dribble < Sinatra::Base
  set :server, 'thin'
  set :sockets, []

  configure do
    register Sinatra::Reloader
  end

  get '/' do
    File.read('./frontend/index.html')
  end

  get '/ws' do
    request.websocket do |ws|
      ws.onopen do
        o = JSON.generate(data: { torrents: [
                            { hash: 'x', name: 'name', test: 1 },
                            { hash: 'y', name: 'name2', test: 2 }
                          ] })
        ws.send(o)
        settings.sockets << ws
      end

      # ws.onmessage do |msg|
      #  EM.next_tick { settings.sockets.each { |s| s.send(msg) } }
      # end

      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end
