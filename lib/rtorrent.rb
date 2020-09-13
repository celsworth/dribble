# frozen_string_literal: true

require 'xmlrpc/rtorrent'

class Rtorrent
  def initialize(host, port)
    @host = host
    @port = port
  end

  # example: rtorrent.call('d.multicall2', '', 'main', 'd.name=', 'd.hash=')
  def call(*args)
    rtorrent.call(*args)
  end

  # example: rtorrent.multicall(['get_download_rate'], ['get_upload_rate'])
  # TODO: params?
  def multicall(commands)
    rtorrent.multicall(commands)
  end

  private

  def rtorrent
    @rtorrent ||= XMLRPC::RTorrent.new(@host, '', @port)
  end
end
