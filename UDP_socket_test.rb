require 'socket'
require 'gosu'

class Main < Gosu::Window
    class Player
        def initialize
            @x,@y = 0,0
        end
        
        def setter(x,y)
            @x, @y = x,y
        end
    end

    def initialize()
        super(1920/2,1080/2)

        @udp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM)
        @udp_socket.bind(Socket.sockaddr_in(0,""))

        @tcp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)

        @server_connected = false

        @players = []
    end

    def establish_connection()
        begin
            if @tcp_socket.connect(Socket.sockaddr_in(2001, "127.0.0.1")) == 0
                @server_connected = true
                puts "Established connection with server."
    
                udp_port = Socket.unpack_sockaddr_in(@udp_socket.getsockname)[0].to_s
    
                @tcp_socket.write(udp_port)
    
                @players << Player.new
            end
        rescue EINPROGRESS, ENETDOWN => e
            p e
            p "Failed to establish a connection with server. Trying again."
            sleep(0.1)
            retry
        end
    end
    

    def get_server_state
        begin
            payload, addrinfo = @udp_socket.recvfrom(1476)
            return payload, addrinfo
        rescue IO::WaitReadable => e
            p e
            return "NIL"
        end
    end

    def get_player_state
        state = []
        state << self.button_down?(Gosu::KbW)
        state << self.button_down?(Gosu::KbS)
        state << self.button_down?(Gosu::KbA)
        state << self.button_down?(Gosu::KbD)
        return state.to_s
    end

    def set_player_state(server_state)
        @players.each do |player|
            player.setter()
        end
    end

    def send_player_state(player_state)
        @udp_socket.send(player_state,0,Socket.sockaddr_in(2000,"127.0.0.1"))
    end

    def update()
        establish_connection() if !@server_connected 
        send_player_state(get_player_state) if @server_connected
    end

    def draw()
        
    end
end

class Server
    class Player
        def initialize(id)
            @id = id
            @x,@y = 0,0
        end
        
        def id()
            return @id
        end

        def setter(x,y)
            @x, @y = x,y
        end

        def x()
            return @x
        end

        def y()
            return @y
        end
    end

    def initialize()
        @tcp_port = 2001
        @udp_port = 2000

        @tcp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
        @tcp_socket.bind(Socket.sockaddr_in(@tcp_port,""))
        @tcp_socket.listen(5)

        @udp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM)
        @udp_socket.bind(Socket.sockaddr_in(@udp_port,""))

        @clients = []
        @players = []

        start
    end

    def start()
        Thread.new do # TCP packet handling
            loop do
              client_socket, client_addrinfo = @tcp_socket.accept
              port, client_ip = Socket.unpack_sockaddr_in(client_addrinfo)
          
              udp_port = client_socket.recv(1024).strip

              @clients << [udp_port, client_ip]
              @players << Player.new(udp_port)

              puts "New client connected: #{client_ip}:#{port}, UDP port: #{udp_port}"
            end
          end

        Thread.new do # UDP packet handling
            sleep(1)
            loop do
                payload, addrinfo = @udp_socket.recvfrom(1476)
                payload = eval(payload)
                
                port, ip_address = Socket.unpack_sockaddr_in(addrinfo)
                

                delta_x = 0
                delta_y = 0

                if payload[0]
                    delta_y += 1
                elsif payload[1]
                    delta_y -= 1
                elsif payload[2]
                    delta_x += 1
                elsif payload[3]
                    delta_x -= 1
                end

                game_state = []

                @players.each do |player|

                    if player.id == port.to_s
                        player.setter(player.x+delta_x,player.y+delta_y)
                        game_state << [port, player.x, player.y]
                    else
                        game_state << [port, player.x, player.y]
                    end
                    puts player.x, player.y
                end

                @clients.each do |client|
                    @udp_socket.send(game_state.to_s, 0,Socket.sockaddr_in(client[0], client[1]))
                end 
            end
        end
    end
end

Server.new
Main.new.show

