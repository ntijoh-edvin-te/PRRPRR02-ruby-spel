require 'socket'
require 'gosu'
require 'securerandom'

include Socket::Constants 

class PacketStruct
    def initialize
        @@all_structs = []
    end
    def struct(type,payload)
    end
end

class Server
    def initialize()
        # Session variables
        @server_session_id = SecureRandom.uuid
        puts "(Server) Started with session id: #{@server_session_id}"

        @clients = []
        @players = []
        
        # Socket init
        tcp_addrinfo = Addrinfo.tcp("127.0.0.1",5000)
        udp_addrinfo = Addrinfo.udp("127.0.0.1",0)
        
        # Handling of threads
        @mutex_clients = Thread::Mutex.new()

        tcp_thread = Thread.new {handle_tcp_endpoint(tcp_addrinfo)}
        udp_thread = Thread.new {handle_udp_endpoint(udp_addrinfo)}
        [tcp_thread,udp_thread].each(&:join)
    end

    def handle_tcp_endpoint(addrinfo) # Handling of TCP streams
        tcp_socket = Socket.new(AF_INET, SOCK_STREAM)
        tcp_socket.bind(addrinfo) 
        tcp_socket.listen(10)
        
        loop do
            begin
                client_socket, _ = tcp_socket.accept
                Thread.new(client_socket) do |client|
                    @mutex_clients.synchronize{
                        @clients << client
                    }
                    loop do
                        stream = client.recv(1024)
                        puts stream
                    end
                end
            rescue => e
                puts "(Server) Errored when attempting TCP 3-way handshake: #{e}"
            end
        end
    end

    def handle_udp_endpoint(addrinfo) # Handling of UDP datagrams
        udp_socket = Socket.new(AF_INET, SOCK_DGRAM)
        udp_socket.bind(addrinfo)
        
        loop do
        end
    end
end

class Client 
    def initialize()
        @id = SecureRandom.uuid
        establish_connection
    end

    def establish_connection
        tcp_socket = Socket.new(AF_INET, SOCK_STREAM)
        tcp_socket.binmode
        begin
            tcp_socket.connect(Addrinfo.tcp("127.0.0.1",5000))
        rescue => e
            puts "(Client) Errored when attempting TCP 3-way handshake #{e}"
            retry
        end
        loop do # Loop to uphold TCP stream
            sleep(1)
            tcp_socket.write(0)
            tcp_socket.flush
        end
    end
end

Thread.new{Server.new}

Client.new
sleep()

