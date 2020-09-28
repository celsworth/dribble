# frozen_string_literal: true

require 'xmlrpc/client'

class XMLRPC::RTorrent < XMLRPC::Client
  def do_rpc(xml, _async = false)
    headers = { 'CONTENT_LENGTH' => xml.size, 'SCGI' => 1 }

    header = headers.to_a.flatten.join("\x00").to_s
    request = "#{header.size}:#{header},#{xml}"

    if @host.start_with? '/' || @host.start_with? '.'
      UNIXSocket.open(@host) { |s| do_request(s, request) }
    else
      TCPSocket.open(@host, @port) { |s| do_request(s, request) }
    end
  end

  def do_request(socket, request)
    socket.write(request)
    socket.read.split(/\n\s*?\n/, 2)[1]
  end
end
