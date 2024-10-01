require 'socket'
require 'gosu'

class Main < Gosu::Window
    def initialize()
        super(1920/2,1080/2)
        @udp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM) 
        @tcp_socket = Socket.new(Socket)
        @x, @y = 0,0
        @is_in_lobby = false
    end

    def get_server_state
        payload, addrinfo = @client_socket.recvfrom_nonblock(1476)
        return payload, addrinfo
    end

    def get_player_state
        state = []
        state << self.button_down?(Gosu::KbW)
        state << self.button_down?(Gosu::KbS)
        state << self.button_down?(Gosu::KbA)
        state << self.button_down?(Gosu::KbD)
        return state.to_s
    end

    def set_player_state(delta_time, server_state)
        #@x = 

    end

    def send_player_state(player_state)
        @client_socket.send(player_state,0,Socket.sockaddr_in(2000,"127.0.0.1"))
    end

    def establish_connection()

    end

    def update()
        if !@is_in_lobby establish_connection()
        send_player_state(get_player_state) if @is_in_lobby
    end

    def draw()
        
    end
end

class Server
    class Player
        def initialize
            @x, @y = 0,0
        end
    end

    def initialize()
        @udp_port = 2000
        @tcp_port = 2001

        @udp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM)
        @udp_socket.bind(Socket.sockaddr_in(@udp_port,""))

        @tcp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
        @tcp_socket.bind(Socket.sockaddr_in(@tcp_port,""))
        @tcp_socket.listen(5)

        @clients = []
        start
    end

    def start()
        Thread.new do # UDP packet handling
            loop do
                payload, addrinfo = @udp_socket.recvfrom(1476)
                payload = eval(payload)

                p addrinfo.ip_address
            end
        end
        Thread.new do # TCP packet handling
            loop do
                p @tcp_socket.recvfrom(1476)
            end
        end
    end
end

Server.new
Main.new.show

