require 'socket'

server = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM)
server.bind(Socket.sockaddr_in(2000,"127.0.0.1"))

Thread.new do
    loop do
        client = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM)
        client.send("ok",0,Socket.sockaddr_in(2000,"127.0.0.1"))
    end 
end

loop do
    data, addr_inf = server.recvfrom(1024)
    p data
end