require "gosu"
require 'socket'

class Server
  def initialize(port)
    @server = TCPServer.new('127.0.0.1', port)
    @clients = []
    puts "Server started on port #{port}"
    start
  end

  def start
    loop do
        if IO.select([@server], nil, nil, 0)
            client = @server.accept_nonblock
            @clients << client
            puts "Client connected: #{client.peeraddr[2]}"
        end
    end
  end
end

server_thread = Thread.new do
  Server.new(2000)
end

class Client
    class Player
        attr_accessor :x, :y, :look_direction
        def initialize(window)
            @sprite = Gosu::Image.new("media/img/char.png")
            @x = @y = 0.0
            @scale = 0.3

            @window = window
            
            @MOVEMENT_MULTIPLIER = 400
            @JUMP_VEL_MAX = 100
            @JUMP_VEL_DEFAULT = 50
            @JUMP_MULTIPLIER = 20
            @CHARGE_MULTIPLIER = 100
            @G = 9.82
            @look_direction = 1

            @isChargingJump = false
            @isMidAir = false
            @jump_vel = 0
        end

        def warp(x, y)
            @x, @y = x, y
        end

        def sprinting?()
            if @window.button_down?(Gosu::KbLeftShift)
                return 1.5
            else
                return 1
            end
        end

        def jumpCharge(delta_time)
            return if @jump_vel == @JUMP_VEL_MAX
            @jump_vel = @JUMP_VEL_DEFAULT if @jump_vel == 0
            @jump_vel = [@jump_vel + @CHARGE_MULTIPLIER * delta_time, @JUMP_VEL_MAX].min
        end

        def gravity(delta_time)
            delta_time *= @JUMP_MULTIPLIER
            delta_y = @jump_vel * delta_time - (0.5 * @G * delta_time ** 2)
            @jump_vel -= @G * delta_time
            return delta_y
        end

        def handle_movement(delta_time)
            effective_speed = @MOVEMENT_MULTIPLIER * sprinting?() * delta_time

            if @window.button_down?(Gosu::KbA)
                @x = [(@x - effective_speed), 0].max
                @look_direction = -1
            end

            if @window.button_down?(Gosu::KbD)
                @x = [(@x + effective_speed), (@window.width - @sprite.width * @scale)].min
                @look_direction = 1
            end
        end

        def handle_jump(delta_time)
            if @window.button_down?(Gosu::KbSpace) && !@isMidAir
                @isChargingJump = true
                jumpCharge(delta_time)
            elsif !@window.button_down?(Gosu::KbSpace) && @isChargingJump
                @isChargingJump = false
                @isMidAir = true
            end
        end

        def apply_gravity(delta_time)
            if @isMidAir
                @y = [(@y - gravity(delta_time)), (@window.height - @sprite.height * @scale)].min
            end

            if (@y + @sprite.height * @scale) == @window.height && !@isChargingJump
                @jump_vel = 0
                @isMidAir = false
            end
        end

        def update()
            delta_time = @window.delta_time
            handle_movement(delta_time)
            handle_jump(delta_time)
            apply_gravity(delta_time)
        end

        def draw
            @sprite.draw(@x, @y, 1, @scale, @scale)
        end
    end


    class Gun
        def initialize(window, player)
            @window = window
            @player = player
            @bullets = []
            
            @rate = 0
            @fire_rate = 5 # 60/s
        end

        def update()
            if @window.button_down?(Gosu::KbP)
                if @rate == @fire_rate
                    bullet = Bullet.new(@player.x, @player.y, @player.look_direction)
                    @bullets << bullet
                    @rate = 0
                else
                    @rate +=1
                end
            end
            
            @bullets.each {|bullet| bullet.update(@window.delta_time)}
        end

        def draw
            @bullets.each {|bullet| bullet.draw}
        end
        class Bullet
            def initialize(x,y,direction)
                @bullet = Gosu::Image.new("media/img/char.png")
                @x, @y = x,y
                @scale = 0.05
                @BULLET_MULTIPLIER = 10000*direction
            end

            def update(delta_time)
                @x += (delta_time*@BULLET_MULTIPLIER)
            end

            def draw
                @bullet.draw(@x, @y, 0, @scale, @scale)
            end
        end
    end

    class Main < Gosu::Window
        WIDTH, HEIGHT = 1920, 1080 

        attr_accessor :delta_time
        def initialize
            super(WIDTH, HEIGHT)
            self.caption = "Main"
            self.resizable = true
            self.fullscreen = true

            @player = Player.new(self)
            @player.warp(WIDTH / 2, 0)
            @gun = Gun.new(self, @player)
            @last_update_time = Gosu.milliseconds
            @delta_time = 0
        end

        def update
            update_time = Gosu.milliseconds
            @delta_time = (update_time - @last_update_time) / 1000.0
            @last_update_time = update_time

            @player.update
            @gun.update
        end

        def draw
            @player.draw
            @gun.draw
        end
    end
    #game = Main.new.show
end