require "gosu"

class Player
    attr_accessor :x, :y, :sprite, :scale, :mass
    def initialize()
        @sprite = Gosu::Image.new("media/img/char.png")
        @x = @y = 0.0
        @scale = 0.3
    end

    def warp(x,y)
        @x, @y = x, y
    end
    
    def draw
        @sprite.draw(@x, @y, 1, @scale, @scale)
    end
end

class Main < Gosu::Window
    WIDTH, HEIGHT = 1920, 1080 
    def initialize()
        super(WIDTH, HEIGHT)
        self.caption = "Main"
        self.resizable = true
        self.fullscreen = true

        @player = Player.new
        @player.warp(WIDTH/2,0)

        @MOVEMENT_MULTIPLIER = 400
        @JUMP_VEL_MAX = 100
        @JUMP_VEL_DEFAULT = 50
        @JUMP_MULTIPLIER = 20
        @CHARGE_MULTIPLIER = 100
        @G = 9.82
        
        @isChargingJump = false
        @isMidAir = false
        @jump_vel = 0
        @last_update_time = Gosu.milliseconds
    end

    def isSprinting?()
        if self.button_down?(Gosu::KbLeftShift)
           return 1.5 
        else 
            return 1
        end
    end

    def jumpCharge(delta_time) #V0y
        return if @jump_vel == @JUMP_VEL_MAX
        @jump_vel = @JUMP_VEL_DEFAULT if @jump_vel == 0
        @jump_vel = [@jump_vel+@CHARGE_MULTIPLIER*delta_time, @JUMP_VEL_MAX].min
    end

    def gravity(delta_time, jump_vel)
        delta_time *= @JUMP_MULTIPLIER
        delta_y = jump_vel*delta_time-(0.5*@G*delta_time**2)
        @jump_vel -= @G*delta_time
        return delta_y
    end 

    def update # 60/s
        update_time = Gosu.milliseconds
        delta_time = (update_time - @last_update_time) / 1000.0
        @last_update_time = update_time
        
        effective_speed = @MOVEMENT_MULTIPLIER * isSprinting?() * delta_time

        if self.button_down?(Gosu::KbSpace) && !@isMidAir
            @isChargingJump = true
            jumpCharge(delta_time) 
        elsif !self.button_down?(Gosu::KbSpace) && @isChargingJump
            @isChargingJump = false
            @isMidAir = true
        end 

        if self.button_down?(Gosu::KbA)
            @player.x = [(@player.x-effective_speed), 0].max
        end
        if self.button_down?(Gosu::KbD)
            @player.x = [(@player.x+effective_speed), (self.width-@player.sprite.width*@player.scale)].min
        end
    
        if @isMidAir 
            @player.y = [(@player.y - gravity(delta_time, @jump_vel)), (self.height - @player.sprite.height*@player.scale)].min
        end
        
        if (@player.y + @player.sprite.height*@player.scale) == self.height && !@isChargingJump
            @jump_vel = 0
            @isMidAir = false
        end
    end

    def draw
        @player.draw
    end
end

game = Main.new.show