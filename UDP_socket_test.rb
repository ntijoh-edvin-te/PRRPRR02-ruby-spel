require 'socket'
require 'gosu'

# Serializing packet UDP

def pack_udp()

end

# Deserializing packet UDP

def unpack_udp()

end

class Main < Gosu::Window
    def initialize()
        super(1920/2,1080/2)
        @client_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM) 
    end

    def update
        @client_socket.send("W",0,Socket.sockaddr_in(2000,"127.0.0.1")) if self.button_down?(Gosu::KbW)
    end
end

class Server
    def initialize()
        @server_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM)
        @server_socket.bind(Socket.sockaddr_in(2000,"127.0.0.1"))
        @clients = []
        start
    end

    def start()
        Thread.new do # UDP packet handling
            loop do
                p @server_socket.recvfrom(1476)
            end
        end
    end
end

Server.new
Main.new.show

