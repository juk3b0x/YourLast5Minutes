pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

--#include dsa.lua

-------------Varaibles----------------
-------------Projectiles--------------
Projectile = {}
Projectile.__index = Projectile  -- Set metatable for Projectile instances

function Projectile:new(sender)
    local self = setmetatable({}, Projectile)  -- Create new instance
    self.dmg = sender.dmg
    self.range = 10
    self.mspeed = 0
    self.posX = 0
    self.posY = 0
    self.dirX = 1
    self.dirY = 0
    self.sprite = 12
    self.spawnpoint = {0,0}
    self:spawn(sender)
    return self
end

function Projectile:move()
    move(self)
end

function Projectile:die()
    despawn(self)
end

function Projectile:spawn(sender)
    self.mspeed = sender.aspeed
    if sender.sprite == 0 then
        self.spawnpoint[1] = sender.posX - 8
        self.spawnpoint[2] = sender.posY
        self.sprite = 12
        self.dirX = -1
        self.dirY = 0
    elseif sender.sprite == 1 then
        self.spawnpoint[1] = sender.posX + 8
        self.spawnpoint[2] = sender.posY
        self.sprite = 13
        self.dirX = 1
        self.dirY = 0
    elseif sender.sprite == 2 then
        self.spawnpoint[1] = sender.posX
        self.spawnpoint[2] = sender.posY - 8
        self.sprite = 14
        self.dirY = -1
        self.dirX = 0
    elseif sender.sprite == 3 then
        self.spawnpoint[1] = sender.posX
        self.spawnpoint[2] = sender.posY + 8
        self.sprite = 15
        self.dirY = 1
        self.dirX = 0
    end
    self.posX = self.spawnpoint[1]
    self.posY = self.spawnpoint[2]
    self.range = sender.range
end
---------Player-----------------
Player = {
    dmg = 10,
    aspeed = 1,
    mspeed = 1,
    range = 10,
    hp = 100,
    posX = 0,
    posY = 0,
    dirX = 0,
    dirY = 0,
    sprite = 0,

    init = function(self)
        self.posX = 64
        self.posY = 64
        self.dirX = 1
        self.dirY = 1
        self.sprite = 64
    end,

    update = function(self)
        move(self)
        attack(self)
    end
}
-----------------Mob-------------------
Mob = {}
Mob.__index = Mob  -- Set metatable for Mob instances

function Mob:new()
    local self = setmetatable({}, Mob)  -- Create new instance
    self.dmg = 10
    self.mspeed = 1
    self.aspeed = 1
    self.range = 10
    self.hp = 100
    self.posX = 0
    self.posY = 0
    self.dirX = 1
    self.dirY = 0
    self.sprite = 64
    self.spawnpoint = {0,0}
    return self
end

function Mob:move()
    move(self)
end

function Mob:die()
    despawn(self)
end

function Mob:spawn()
    self.spawnpoint[1] = flr(rnd(128))
    self.spawnpoint[2] = flr(rnd(64))
    self.posX = self.spawnpoint[1]
    self.posY = self.spawnpoint[2]
end

function Mob:patrol()
    -- Patrol logic (between two points)
end

function Mob:chase()
    -- Chase player logic
end

grid = {}
mobs = {}
projectiles = {}

function _init()
    Player:init()
    camera(Player.posX, Player.posY)
    init_grid()
    create_map()
    set_map()
    for i = 1, 30 do
        add(mobs, Mob:new())
    end
    for mob in all(mobs) do
        mob:spawn()
    end
end 

function _update()
    Player:update()
    for mob in all(mobs) do
        mob:move()
    end
    for projectile in all(projectiles) do
        if projectile.range <= 0 then
            projectile:die()
        else projectile.range -= 1 end
        projectile:move()
    end
    _draw()
    
end

function _draw()
    cls()
    map(0, 0, 0, 0, 128, 64)
    
    draw(Player)
    for mob in all(mobs) do
        draw(mob)
    end
    for projectile in all(projectiles) do
        draw(projectile)
    end
end


----------------Stats------------------







-----------------MAP-------------------

m_size = 129
roughness = flr(rnd(3)) -1

function adjust_roughness(size)
    adj = 2
    chance = rnd()
    if chance > 0.9 then
        adj = rnd((adj*2)+1)-adj
    end
    if chance >= 0.75 then adj+=1 end
    return adj
end
function init_grid()
    for x = 1, m_size do
        local row = ""
        for y = 1, m_size do
            row = row .. "0" -- Append "0" for each column in the row
        end
        grid[x] = row -- Assign the constructed row to the grid
    end
    set_grid(1, 1, 0) --flr(rnd(16)))           -- Random value 0-15
    set_grid(1, m_size, 4) --flr(rnd(16))) -- Random value 0-15
    set_grid(m_size , 1, 4) --flr(rnd(16))) -- Random value 0-15
    set_grid(m_size , m_size, 9) --flr(rnd(16))) -- Random value 0-15
end
function set_grid(x, y, value)
    local row = grid[x]             -- Access the appropriate row
    local hex_char = sub("0123456789abcdef", value, value) -- Convert value (0-15) to hex
    grid[x] = sub(row, 1, y - 1) .. hex_char .. sub(row, y + 1) -- Update the character at the correct position
end
function get_grid(x, y)
    local row = grid[x]             -- Access the correct row
    local char = sub(row, y, y)     -- Extract the character at position y
    return tonum(char, 0x1)          -- Convert hex character to a number (0-15)
end
function create_map()
    local size = m_size-1
    while size > 1 do
        local half = size / 2
        diamond(size, half)
        square(size, half)
        size = size / 2
    end
end
function diamond(size, half)
    for x = 1, m_size -1, size do
        for y = 1, m_size-1, size do
            local x1 = x
            local x2 = x + size
            local y1 = y
            local y2 = y + size
            local cornersum = get_grid(x1, y1) + get_grid(x2, y1) + get_grid(x1, y2) + get_grid(x2, y2)
            local avg = flr(cornersum / 4)
            local val = avg + adjust_roughness(size)
            if val >= 9 then val = 9
            elseif val <= 0 then val = 0 end
            set_grid(min(x + half, m_size), min(y + half, m_size), val)
        end
    end
end
function square(size, half)
    for x = 1, m_size - 1, half do
        for y = (x + half - 1) % size + 1, m_size - 1, size do
            local x1 = (x - half - 1 + m_size - 1) % (m_size - 1) + 1
            local x2 = (x + half - 1) % m_size + 1
            local y1 = (y + half - 1) % m_size + 1
            local y2 = (y - half - 1 + m_size - 1) % (m_size - 1) + 1
            local cornersum = get_grid(x1, y) + get_grid(x2, y) + get_grid(x, y2) + get_grid(x, y1)
            local avg = flr(cornersum / 4)
            local val = avg + adjust_roughness(size)
            if val >= 15 then val = 15
            elseif val <= 0 then val = 0 end
            set_grid(x, y, val)
        end
    end
end
function set_map()
    for x = 0, 127 do
        for y = 0, 63 do
            local value = get_grid(x+1, y+1)
            local col = 0
            if value < 2 then
                col = set_shadow(x, y, 4, 0) --colors[3]
            elseif value >= 2 and value < 4 then
                if get_grid_same_neighbors(x, y, get_level(x, y)) == 0 then
                    col = 50 --colors[4]
                elseif get_grid_same_neighbors(x, y, get_level(x, y)) == 1 then
                    col = 51 --colors[5]
                elseif get_grid_same_neighbors(x, y, get_level(x, y)) <= 3 then
                    col = 49 --colors[5]
                else
                    col = 1
                end
                if set_shadow(x, y, 4, 1) != 1 then
                    col = set_shadow(x, y, 4, 1) --colors[3]
                end
                --col = set_shadow(x, y, 4, 1) --colors[3]
            elseif value >= 4 and value < 6 then
                col = set_shadow(x, y, 4, 2) --colors[3]
            elseif value >= 6 and value < 8 then
                col = set_shadow(x, y, 4, 3) --colors[3]
            else 

                if get_grid_same_neighbors(x, y, get_level(x, y)) == 0 then
                    col = 4 --colors[4]
                elseif get_grid_same_neighbors(x, y, get_level(x, y)) == 1 then
                    col = 20 --colors[5]
                elseif get_grid_same_neighbors(x, y, get_level(x, y)) <= 3 then
                    col = 36 --colors[5]
                elseif get_grid_same_neighbors(x, y, get_level(x, y)) > 3 then
                    col = 52 --colors[5]
                end
            end--colors[4]
        --draw_random_rotated_tile(col + 75, x * 8, y * 8)
            if col == 0 then
                mset(x,y-1,16+75)
            end
            mset(x,y,col + 75)
        end
    end
end

function get_grid_same_neighbors(x, y, value)
    local neighbors = 0
    if get_level(x + 1, y) == value then
        neighbors += 1
    end
    if get_level(x, y + 1) == value then
        neighbors += 1
    end
    if get_level(x - 1, y) == value then
        neighbors += 1
    end
    if get_level(x, y - 1) == value then
        neighbors += 1
    end
    return neighbors
end

function set_shadow(x, y, value, col)
    local shadow = col
    if get_level(x, y - 1) == value then
        shadow = col + 16
    end
    return shadow
end

function set_tree(x, y, value, col)
    local tree = col
    if get_level(x, y + 1) == value then
        tree = col + 16
    end
    return tree
end


function get_level(x, y)
    if ((x+1) < 1 or (x+1) > (m_size-1) or (y+1) < 1 or (y+1) > ((m_size-1)/2)) then
        return 0
    end
    local value = get_grid(x + 1, y + 1) 
    if value < 2 then
        return 0 
    elseif value >= 2 and value < 4 then
        return 1 
    elseif value >= 4 and value < 6 then
        return 2 
    elseif value >= 6 and value < 8 then
        return 3 
    else
        return 4 
    end
end



function MoveAndCollision(entity, moveX, moveY)
    local speed = entity.mspeed
    local newPosX = entity.posX + moveX * speed
    local newPosY = entity.posY + moveY * speed
    local leftTile   = flr((newPosX) / 8)
    local rightTile  = flr((newPosX + 7) / 8) -- Consider entity width
    local topTile    = flr((newPosY) / 8)
    local bottomTile = flr((newPosY + 7) / 8) -- Consider entity height
    if fget(mget(leftTile, topTile), 0) or
        fget(mget(rightTile, topTile), 0) or
        fget(mget(leftTile, bottomTile), 0) or
        fget(mget(rightTile, bottomTile), 0) then
        moveX = 0
        moveY = 0
    end
    if leftTile < 0 or rightTile >= 128 or topTile < 0 or bottomTile >= 64 then
        moveX = 0
        moveY = 0
    end
    if getmetatable(entity) == Player or getmetatable(entity) == Mob then
        for projectile in all(projectiles) do
            if flr(projectile.posX / 8) == flr(entity.posX / 8) and 
                flr(projectile.posY / 8) == flr(entity.posY / 8) then
                receivedmg(entity, projectile.dmg)
                projectile.range = flr(projectile.range / 2)
            end
        end
    end
    entity.posX = entity.posX + moveX * entity.mspeed
    entity.posY = entity.posY + moveY * entity.mspeed
end
function move(entity)
    
    
    if entity == Player then
        entity.dirX = 0
        entity.dirY = 0
        if btn(0) then
            entity.sprite = 0
            entity.dirX = -1
        end

        if btn(1) then
            entity.sprite = 1
            entity.dirX = 1
        end

        if btn(2) then
            entity.sprite = 2
            entity.dirY = -1
        end

        if btn(3) then
            entity.sprite = 3
            entity.dirY = 1
        end
        camera(entity.posX - 64, entity.posY - 64)
    
    elseif getmetatable(entity) == Mob then
        entity.dirX = 0
        entity.dirY = 0
        btns = {0,1,2,3}
        rndbtn = rnd(btns)
        if rndbtn == 0 then
            entity.sprite = 64
            entity.dirX = -1
                
        elseif rndbtn == 1 then
            entity.sprite = 65
            entity.dirX = 1
                
        elseif rndbtn == 2 then
            entity.sprite = 80
            entity.dirY = -1
               
        elseif rndbtn == 3 then
                entity.sprite = 81
                entity.dirY = 1
        end
    elseif getmetatable(entity) == Projectile then
        if entity.dirX == -1 then
            entity.sprite = 12
        elseif entity.dirX == 1 then
            entity.sprite = 13
        elseif entity.dirY == -1 then
            entity.sprite = 14
        elseif entity.dirY == 1 then
            entity.sprite = 15
        end
    end 
    MoveAndCollision(entity, entity.dirX, entity.dirY)
end

function attack(sender)
    if sender == Player then
        if btn(4) then
            add(projectiles, Projectile:new(sender))
        end
    end
end
function draw(entity)
    -- Zeichne den Spieler basierend auf der Blickrichtung
    spr(entity.sprite, entity.posX, entity.posY)
end
function despawn(entity)
    if getmetatable(entity) == Projectile then
        del(projectiles, entity)  
    end
    if getmetatable(entity) == Mob then
        del(mobs, entity)
    end
end
function receivedmg(entity,dmg)
    if entity == Player then
        entity.hp -= dmg
    else
        entity.hp -= dmg
        if entity.hp <= 0 then
            entity:die()
        end
    end
end
----------------Portal-----------------








-----------------Boss------------------



-----------------Camera----------------



__gfx__
00888000000888000008800000088000000888007777777777777777777777777777777777777777777777777777777700000000000000000000000000000000
0088880000888800008888000088880000088c000777777777777777777777777777777777777777777777777777777700000000000000000000800000000000
00cc88000088cc0000888800008cc80000888c000777777777777777777777777777777777777777777777777777777700000000000000000000900000000000
00cc88000088cc0000888800008cc800008888000777777777777777777777777777777777777777777777777777777700000000000000000000a000000a0000
008888000088880000888800008888000088880007777777777777777777777777777777777777777777777777777777089aa000000aa9800000a000000a0000
00888800008888000088880000888800008888000077777777777777777777777777777777777777777777777777777700000000000000000000000000090000
00888800008888000088880000888800000880000077777777777777777777777777777777777777777777777777777700000000000000000000000000080000
00880000000088000008000000080000000880000007777777777777777777777777777777777777777777777777777700000000000000000000000000000000
008880000008880000088000000880007777700070077777777777777777777777777777777777777777777777777777bbbb0000bbbbbbbbbbbbbbbbbbbbbbbb
008888000088880000888800008888007777700770077777777777777777777777777777777777777777777777777777bbb000000bbbbbbbbbbbbbbbbbbbbbbb
00cc88000088cc0000888800008cc8007777700000007777777777777777777777777777777777777777777777777777bbb00bb00bbbbbbbbbbbbbbbbbbbbbbb
00cc88000088cc0000888800008cc8007777000000007777777777777777777777777777777777777777777777777777bbbbbbb00bbbbbbbbbbbbbbbbbbbbbbb
008888000088880000888800008888007777007777007777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
008888000088880000888800008888007777007777007777777777777777777777777777777777777777777777777777bbbbbbbb0000bbbbbbbbbbbbbbbbbbbb
008888000088880000888800008888007777777777777777777777777777777777777777777777777777777777777777bbbbbbbb00000bbbbbbbbbbbbbbbbbbb
000080000008080000008000000080007777777777777777777777777777777777777777777777777777777777777777bbbbbbbb00000bbbbbbbbbbbbbbbbbbb
777777777777777777777777777777777777777777007777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
777777777777777777777777777777777777777777007777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbb00bbbbbbbbb
777777777777777777777777777777777777777770007777777777777777777777777777777777777777770077777777bbbbbbbbbbbbbbbbbbbbb00bbbbbbbbb
777777777777777777777777777777777777777770007777777777700777777777000000077777777777770007777777bbbbbbbbbbbbbbbbbbb00bbbbbbbbbbb
777777777777777777777000777777777777777770007777777770000077777777000000077777777777770007777777bbbbbbbbbbbbbbbb00000bbbbbbbbbbb
777777777777777777700000777777777777777770007777777700000077777777700077777777777777770000777777bbbbbbbbbbbbbbbb00000bbbbbbbbbbb
777777777777777777700000777777777777777700007777777700777777777777700777777000777777700000777777bbbbbbbbbbbbbbbb000bbbbbbbbbbbbb
777777777777777777700007777777777777777700007777777700777777777777700777700000777777700000077777bbbbbbbbbbbbbbbb00bbbbbbbbbbbbbb
777777777777777777700007777777777777777000007777777700777777777777700777000077777777700070077777bbbbbbbbbbbbbbbbbbbb000bbbbbbbbb
777777777777777777700077777777777777777007007777777700777777777777700777000000777777700070077777bbbbbbbbbbbbbbbbbbb0000bbbbbbbbb
777777777777777777700077777777777777770007000777777700777777777777700777000000777777700070077777bbbbbbbbbbbbbbbbbbb0000bbbbbbbbb
777777777777777777700000777777777777770070000077777700077777777777700777000777777777700770000777bbbbbbbbbbbbbbbbbbb0000bbbbbbbbb
777777777777777777700000007777777777700070000077777770077777777777700777700077777777700777000777bbbbbbbbbbbbbbbbbbb0000bb000bbbb
777777777777777777700770007777777777700777700777777770007777777777700777770000777777777777777777bbbbbbbbbbbbbbbbbbb000bbb000bbbb
777777777777777777777777007777777777000777777777777777000077777777700777777000777777777777777777bbbbbbbbbbbbbbbbbbb0000bb000bbbb
777777777777777777777777777777777777007777777777777777700077777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbb0000bb000bbb
00eee000000eee0088888888888888888888888888888888000000000000000000000000000000000000000033355533333b3b33b33333b33333333333555533
00eeee0000eeee0088888888888888888888888888888888000000000000000000000000000000000000000033355533b333b3b33333333b3333333355554453
00ccee0000eecc00888888888888888888888888888888880000000000000000000000000000000000000000333455333333b333333333333333333355445445
00ccee0000eecc00888888888888888888888888888888880000000000000000000000000000000000000000333445333b3b333b333333333333333355454445
00eeee0000eeee0088888888888888888888888888888888000000000000000000000000000000000000000033344433b333333333b3b3333333333354544455
00eeee0000eeee008888888888888888888888888888888800000000000000000000000000000000000000003344443333b33b3b333b33333333333354545555
00eeee0000eeee0088888888888888888888888888888888000000000000000000000000000000000000000033444433b33333b333333b333333333355445455
00ee00000000ee0088888000000888888888888888888888000000000000000000000000000000000000000033444433333b333b333333333333333355555555
000ee000000ee00088888000000088888888888888888888000000000000000000000000000000000000000033aaaa3355555555555555555555555535555553
00eeee0000eeee008880000000008888888888888888888800000000000000000000500000000000000000003aaaaaa355555555555555555555555554454445
00eeee0000ecce00888000000000888888888888888888880000000000000000005345000000000000000000aaaaaaaa35555553355555533555555354554445
00eeee0000ecce00888000000008888888888888888888880000000000000000054553400000000000000000999aaaaa33555533335555333355553355544445
00eeee0000eeee0088000888008888888888888888888888000000000000000005355400000000000000000099999aaa33333333333333333333333355444455
00eeee0000eeee00800088880088888888888888888888880000000000000000044343500000000000000000999999aa33333333333333333333333354444545
00eeee0000eeee0080088880008888888888888888888888000000000000000000344500000000000000000099999999b33333b333333b333333333355444445
000e0000000e000080088800080008888888888888888888000000000000000000040000000000000000000039999993333b333b333333333333333355555555
00000000000000008000000000000088888888888888888800000000000000000000000000000000000000000000000000000000000000000000000055555555
00000000000000008800000800080000888888888888888800000000000000000000000000000000000000000000000000000000000000000000000055454445
00000000000000008888888800888800088888888888888800000000000000000000000000000000000000000000000000000000000000000000000054444455
00000000000000008888888800008800080088888888888800000000000000000000000000000000000000000000000000000000000000000000000054444455
00000000000000008888888880000000800000088888888800000000000000000000000000000000000000000000000000000000000000000000000054554555
00000000000000008888888888000000800000088888888800000000000000000000000000000000000000000000000000000000000000000000000054445445
00000000000000008888888888888888880088888888888800000000000000000000000000000000000000000000000000000000000000000000000055444445
00000000000000008888888888888888880008880000888800000000000000000000000000000000000000000000000000000000000000000000000055555555
00000000000000008888888888888880000008880000888800000000000000000000000000000000000000000000000033333393333333333333333355544555
0000000000000000888888888888888000008888008888880000000000000000000000000000000000000000000000003b3b39a9333333b3332b333355445544
00000000000000008888888888888888888888880008888800000000000000000000000000000000000000000000000033b33393383333333223b3b355555545
0000000000000000888888888888888888888888000888880000000000000000000000000000000000000000000000003333333382b333333e33b33355555555
00000000000000008888888888888888888800000008888800000000000000000000000000000000000000000000000033333333383338333333b33344555455
0000000000000000888888888888888888880000088888880000000000000000000000000000000000000000000000003393333333338283333bb33355544455
00000000000000008888888888888888888888888888888800000000000000000000000000000000000000000000000039a933b333333b33b33b333355445554
00000000000000008888888888888888888888888888888800000000000000000000000000000000000000000000000033933333b3333333b333333b55555545
__gff__
0000000000000000000000008080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000001000000000000000001000001000000010000000000000000000000000000000100000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
