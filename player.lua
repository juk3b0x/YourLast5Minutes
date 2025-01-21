player = {

    --player stats
    mspeed = 1  --movement speed
    dmg = 1		--attack damage
    aspeed = 1	--attack speed
    hp = 10		--health points
    range = 10	--range for attacks
    evasion = 1	--chance to dodge an incoming attack
    gold = 0 	--initial gold
    sp = 0		--initial free skill points
    -- movement
    x = 0
    y = 0
    direction = r
    --functions
    function increasemspeed(percent)
        player.mspeed = (player.mspeed/100*percent) + player.mspeed
    end
    function increasedmg(percent)
        player.dmg = (player.dmg/100*percent) + player.dmg
    end
    function increaseaspeed(percent)
        player.aspeed = (player.aspeed/100*percent) + player.aspeed
    end 
    function increasehp(percent)
        player.hp = (player.hp/100*percent) + player.hp
    end
    function increaserange(percent)
        player.range = (player.range/100*percent) + player.range
    end
    function increaseevasion(percent)
        player.evasion = (player.evasion/100*percent) + player.evasion
    end
    function increasegold(val)
        player.gold = player.gold + val
    end
    function increasesp(val)
        player.sp = player.sp + val
    end
    function decreasehp(val)
        player.hp = player.hp - val
    end
    function decreasegold(val)
        player.gold = player.gold - val
    end
    function decreasesp(val)
        player.sp = player.sp - val
    end
    function attack(movdir, range)
        if movdir= r then
            -- sapwn projectile and move it for (range) tiles to then right for until it hits a wall or enemy
        end
        elseif movdir= l then
            -- sapwn projectile and move it for (range) tiles to then left for until it hits a wall or enemy
        end
        elseif movdir= u then
            -- sapwn projectile and move it for (range) tiles to then up for until it hits a wall or enemy
        end
        else
            -- sapwn projectile and move it for (range) tiles to then down for until it hits a wall or enemy
        end
    end
    function move(movdir)
        if movdir = r then
            player.x = player.x + 1
        end
        elseif movdir = l then
            player.x = player.x - 1
        end
        elseif movdir = u then
            player.y = player.y + 1
        end
        else 
            player.y = player.y - 1
        end
    end

}