require "gosu"

class Player
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
        delta_time = @window.delta_time()
        handle_movement(delta_time)
        handle_jump(delta_time)
        apply_gravity(delta_time)
    end

    def draw
        @sprite.draw(@x, @y, 1, @scale, @scale)
    end
end


class Gun
    class Bullet < self
        def initialize(x,y,direction)
            @bullet = Gosu::Image.new("media/img/char.png")
            @x, @y = x,y
            @direction = direction
            @scale = 0.1
        end

        def update
            @x += @direction
        end

        def draw
            @bullets.draw(@x, @y, 0, @scale, @scale)
        end
    end

    def initialize(window)
        @window = window
        @bullets = []
    end
    
    def update()
        delta_time = @window.delta_time()

        p @window

        if @window.button_down?(Gosu::KbP)
            bullet = Bullet.new(@window.player.x, @window.player.y, @window.player.look_direction)
            @bullets << bullet
        end
        
        @bullets.each {|bullet| bullet.update}
    end

    def draw
        @bullets.each {|bullet| bullet.draw}
    end
end

class Main < Gosu::Window
    WIDTH, HEIGHT = 1920, 1080 

    def initialize
        super(WIDTH, HEIGHT)
        self.caption = "Main"
        self.resizable = true
        self.fullscreen = true

        @player = Player.new(self)
        @player.warp(WIDTH / 2, 0)
        @gun = Gun.new(self)
        @last_update_time = Gosu.milliseconds
    end

    def delta_time
        update_time = Gosu.milliseconds
        delta_time = (update_time - @last_update_time) / 1000.0
        @last_update_time = update_time
        return delta_time
    end

    def update
        @player.update
        @gun.update
    end

    def draw
        @player.draw
        @gun.draw
    end
end

game = Main.new.show
