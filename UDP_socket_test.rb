require 'socket'
require 'gosu'
require 'securerandom'

class Client < Gosu::Window
    class Player
        def initialize(id)
            @x,@y = 500,500
            @id = id
            @sprite = Gosu::Image.new("media/img/char.png")
            @scale = 0.5
        end
        
        def setter(x,y)
            @x, @y = x,y
        end

        def draw
            @sprite.draw(@x, @y, 1, @scale, @scale)
        end

        def id()
            return @id
        end
    end

    WIDTH, HEIGHT = 1920,1080
    def initialize()
        super(WIDTH, HEIGHT)
        self.fullscreen = true

        @udp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM)
        @tcp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)

        @server_connected = false

        @players = []

        @id = ""
    end

    def generate_id
        return SecureRandom.uuid()
    end

    def establish_connection()
        begin
            if @tcp_socket.connect(Socket.sockaddr_in(2001, "127.0.0.1")) == 0
                @server_connected = true
                
                @id = generate_id 
                @tcp_socket.write(@id)

                puts "Established connection with server as #{@id}"
    
                @players << Player.new(@id)
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
            payload, _ = @udp_socket.recvfrom(1476)
            return eval(payload)
        rescue IO::WaitReadable => e
            p e
            return "NIL"
        end
    end

    def get_player_state
        state = []
        state << @id
        state << self.button_down?(Gosu::KbW)
        state << self.button_down?(Gosu::KbS)
        state << self.button_down?(Gosu::KbA)
        state << self.button_down?(Gosu::KbD)
        return state.to_s
    end

    def set_player_state(server_state)
        if server_state != "NIL"
            server_state.each do |state|
                player = @players.find { |p| p.id == state[0].to_s }
                
                if player
                    player.setter(state[1], state[2])
                else
                    @players << Player.new(state[0])
                end
            end
        end
    end    

    def send_player_state(player_state)
        @udp_socket.send(player_state,0,Socket.sockaddr_in(2000,"127.0.0.1"))
    end

    def update()
        establish_connection() if !@server_connected 
        send_player_state(get_player_state) if @server_connected
        set_player_state(get_server_state)
    end

    def draw()
        @players.each do |player|
            player.draw
        end
    end
end

class Server
    class Player
        def initialize(id)
            @id = id
            @x,@y = 0,0
        end
        
        def setter(x,y)
            @x += x
            @y += y
        end
        
        def id()
            return @id
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
        @tcp_socket.listen(10)

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
              tcp_port, client_ip = Socket.unpack_sockaddr_in(client_addrinfo)
          
              id = client_socket.recv(1024)

              @clients << [id, client_ip]
              @players << Player.new(id)

              puts "New client #{client_ip}:#{tcp_port} connected as: #{id}"
            end
          end

        Thread.new do # UDP packet handling
            sleep(1)
            loop do
                payload, addrinfo = @udp_socket.recvfrom(1476)
                payload = eval(payload)

                @clients.each do |client| 
                    if !client[2] && payload[0] == client[0]
                        client << Socket.unpack_sockaddr_in(addrinfo)[0]
                    end
                end

                delta_x = 0
                delta_y = 0

                if payload[1]
                    delta_y -= 5
                end
                if payload[2]
                    delta_y += 5
                end
                if payload[3]
                    delta_x -= 5
                end
                if payload[4]
                    delta_x += 5
                end

                game_state = []

                @players.each do |player|
                    if player.id == payload[0]
                        player.setter(delta_x,delta_y)
                        game_state << [player.id, player.x, player.y]
                    else
                        game_state << [player.id, player.x, player.y]
                    end
                end

                @clients.each do |client| # [id, client_ip, udp_port]
                    puts ("\nClient: #{client} \n")
                    @udp_socket.send(game_state.to_s, 0, Socket.sockaddr_in(client[2], client[1]))
                end
            end
        end
    end
end

Server.new
Client.new.show

