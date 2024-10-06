require 'socket'
require 'gosu'
require 'securerandom'

include Socket::Constants 

class Server
    def initialize()
        # Session variables
        @server_session_id = SecureRandom.uuid
        puts "Started server with session id: #{@server_session_id}"

        @clients = []
        @players = []
        
        # Socket init
        tcp_addrinfo = Addrinfo.tcp("0.0.0.0",0)
        udp_addrinfo = Addrinfo.udp("0.0.0.0",0)
        
        # Handling of threads
        @mutex = Thread::Mutex.new()

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
                Thread.new{
                    puts client_socket
                }
            rescue => e
                puts "An error occured when attempting a TCP 3-Way Handshake: #{e}"
                retry
            end
            @mutex.synchronize{
            }
        end
    end

    def handle_udp_endpoint(addrinfo) # Handling of UDP datagrams
        udp_socket = Socket.new(AF_INET, SOCK_DGRAM)
        udp_socket.bind(addrinfo)
        
        loop do
            @mutex.synchronize{
            }
        end
    end
end

Server.new