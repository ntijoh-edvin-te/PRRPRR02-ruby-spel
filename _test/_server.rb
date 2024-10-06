require 'socket'
require 'gosu'
require 'securerandom'

include Socket::Constants 

class PacketStruct
    def initialize
        @all_structs = []
    end
    def struct(type,payload)
    end
end

class Server
    def initialize()
        @SESSION_ID = SecureRandom.uuid
        @TCP_ADDRINFO = Addrinfo.tcp("127.0.0.1",5000)
        @UDP_ADDRINFO = Addrinfo.udp("127.0.0.1",0)
        
        @TIMEOUT_CLIENT = 5
        
        @clients = []

        puts "(Server) Started with session id: #{@SESSION_ID}"
        
        Thread.new {tcp_handler(@TCP_ADDRINFO)}
        Thread.new {udp_handler(@UDP_ADDRINFO)}
    end

    def tcp_handler(addrinfo)
        socket = Socket.new(AF_INET, SOCK_STREAM)
        socket.bind(addrinfo) 
        socket.listen(10)

        loop do
            ready = IO.select([socket, *@clients], nil, nil, @TIMEOUT_CLIENT)

            if ready
                  if ready[0].include?(socket)
                    client_socket, _ = socket.accept
                    puts "(Server) New client connected: #{client_socket}"
                    @clients << client_socket
                end
      
                  ready[0].each do |client|
                    next if client == socket
        
                    begin
                        data = client.recv(10)
                        if data.empty?
                            puts "(Server) Client #{client} disconnected."
                            @clients.delete(client)
                            client.close
                        end
                    rescue => e
                        puts "(Server) Error handling client #{client}: #{e}"
                        @clients.delete(client)
                        client.close
                    end
                end
            end
        end
    end 

    def udp_handler(addrinfo)
        socket = Socket.new(AF_INET, SOCK_DGRAM)
        socket.bind(addrinfo)
        
        loop do
        end
    end
end

class Client 
    def initialize()
        @SESSION_ID = SecureRandom.uuid
        Thread.new{tcp_handler}
    end

    def tcp_handler
        tcp_socket = Socket.new(AF_INET, SOCK_STREAM)
        begin
            tcp_socket.connect(Addrinfo.tcp("127.0.0.1",5000))
        rescue => e
            puts "(Client) Errored when attempting TCP 3-way handshake #{e}"
            retry
        end

        loop do #
            sleep(1)
            tcp_socket.write(1)
            tcp_socket.flush
        end
    end
end

Server.new

Client.new
Client.new
Client.new
Client.new
Client.new

sleep()