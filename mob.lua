mob = {
    dmg = 10
    mspeed = 1
    hp = 100
    x = 0
    y = 0
    sprites = {1,2}
    function move(movdir)
        if movdir == "u" then
            y = y + mspeed
        elseif movdir == "d" then
            y = y - mspeed
        elseif movdir == "l" then
            x = x - mspeed
        else
            x = x + mspeed
        end
    end
    function attack()
        --attack player for dmg
    end
    function die()
        --despawn object and sprite
        --give player gold
    end
    function spawn()
        --spawn object and sprite
    end
    function patrol()
        --patrol between two points
    end
    function chase()
        --chase player
    end
    
}