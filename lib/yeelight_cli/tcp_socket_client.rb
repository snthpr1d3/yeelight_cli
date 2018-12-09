require 'socket'

# The class simply wrapes the TCPSocket client
class YeelightCli::TCPSocketClient
  def initialize(host, port)
    @host = host
    @port = port
  end

  def request(cmd)
    socket = TCPSocket.open(@host, @port)
    socket.puts(cmd)
    json_data = socket.gets.chomp
    socket.close

    JSON.parse(json_data)
  end
end
