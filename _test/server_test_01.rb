require 'socket'
require 'gosu'
require 'securerandom'

class Client < Gosu::Window
    class Player
        def initialize(id)
            @x,@y = 500,500
            @id = id
            @img = Gosu::Image.new("media/img/char.png")
            @scale = 0.5
        end
        
        def setter(x,y)
            @x, @y = x,y
        end

        def draw
            @img.draw(@x, @y, 1, @scale, @scale)
        end

        def id()
            return @id
        end
    end

    WIDTH, HEIGHT = 1920,1080
    def initialize
        super(WIDTH, HEIGHT)
        self.fullscreen = true

        @udp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM)
        @tcp_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)

        @is_conn = false

        @player_self
        @players = []

        @id = ""
    end

    def gen_id
        return SecureRandom.uuid()
    end

    def est_conn
        begin
            if @tcp_socket.connect(Socket.sockaddr_in(2001, "127.0.0.1")) == 0
                @is_conn = true
                
                @id = gen_id 
                @tcp_socket.write(@id)

                puts "Established connection with server as #{@id}"
    
                @player_self = Player.new(@id)
                @players << @player_self
            end
        rescue EINPROGRESS, ENETDOWN => e
            p e
            p "Failed to establish a connection with server. Trying again."
            sleep(0.1)
            retry
        end
    end
    
    def get_s_state
        begin
            payload, _ = @udp_socket.recvfrom(1476)
            return eval(payload)
        rescue IO::WaitReadable => e
            p e
            return "NIL"
        end
    end

    def get_p_state
        state = []
        state << @id
        state << self.button_down?(Gosu::KbW)
        state << self.button_down?(Gosu::KbS)
        state << self.button_down?(Gosu::KbA)
        state << self.button_down?(Gosu::KbD)
        return state.to_s
    end

    def set_p_state(s_state)
        if s_state != "NIL"
            s_state.each do |s|
                p = @players.find { |p| p.id == s[0].to_s }
                
                if p
                    p.setter(s[1], s[2])
                else
                    @players << Player.new(s[0])
                end
            end
        end
    end    

    def send_p_state(p_state)
        @udp_socket.send(p_state,0,Socket.sockaddr_in(2000,"127.0.0.1"))
    end

    def update()
        est_conn() if !@is_conn 
        send_p_state(get_p_state) if @is_conn
        set_p_state(get_s_state)
    end

    def draw()
        @players.each do |p|
            p.draw
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
        @tcp_socket.bind(Socket.sockaddr_in(@tcp_port,"0.0.0.0"))
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
                    @udp_socket.send(game_state.to_s, 0, Socket.sockaddr_in(client[2], client[1]))
                end
            end
        end
    end
end

Server.new
Client.new.show

