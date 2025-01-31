pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

--#include dsa.lua

-------------Varaibles----------------
----------------Player-----------------
Player = {
    dmg = 10,
    mspeed = 1,
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
        self.sprite = flr(rnd(3))
    end,

    update = function(self)
        move(self)
    end,
    --function attack()
      --  shoot(self)
        --dealDMG(self, Mob)
    --end
}
-----------------Mob-------------------
Mob = {}
Mob.__index = Mob  -- Set metatable for Mob instances

function Mob:new()
    local self = setmetatable({}, Mob)  -- Create new instance
    self.dmg = 10
    self.mspeed = 1
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

--function Mob:attack()
    --dealDMG(self, Player)
--end

function Mob:die()
    -- Despawn object and sprite
    -- Give player gold
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
    for i = 1, 10 do
        add(mobs, Mob:new())
    end
    print("before spawn")
    for mob in all(mobs) do
        mob:spawn()
    end
    print("after spawn")
end 

function _update()
    Player:update()
    for mob in all(mobs) do
        mob:move()
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
                col = set_shadow(x, y, 4, 1) --colors[3]
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

function draw_random_rotated_tile(tile, x, y)
    local rotations = {0, 90, 180, 270}
    local random_index = flr(rnd(4)) + 1
    local rotation = rotations[random_index]

    local sx = (tile % 16) * 8  -- X-Position in der Spritemap
    local sy = flr(tile / 16) * 8  -- Y-Position in der Spritemap

    -- Zeichnet den Sprite mit der gewれさhlten Rotation
    if rotation == 0 then
        spr(tile, x, y)
    elseif rotation == 90 then
        sspr(sx, sy, 8, 8, x, y, 8, 8, true, false)  -- 90るぬ = flip x
    elseif rotation == 180 then
        sspr(sx, sy, 8, 8, x, y, 8, 8, true, true)  -- 180るぬ = flip x + flip y
    elseif rotation == 270 then
        sspr(sx, sy, 8, 8, x, y, 8, 8, false, true)  -- 270るぬ = flip y
    end
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

    local pX = flr(entity.posX / 8)    
    local pY = flr(entity.posY / 8)
    local gridX = pX + moveX
    local gridY = pY + moveY

        if (entity.posX % 8 == 0 and 
            get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4 and 
            get_level(gridX, pY + 1) > 0 and get_level(gridX, pY + 1) < 4) or
            entity.posX % 8 != 0 or
            (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4) then
                entity.posX = entity.posX + moveX*entity.mspeed
        end
            pX = flr(entity.posX / 8)
    
        if (entity.posY % 8 == 0 and 
            get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4 and 
            get_level(pX + 1, gridY) > 0 and get_level(pX + 1, gridY) < 4) or
            entity.posY % 8 !=  0 or
            (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4) then
                entity.posY = entity.posY + moveY*entity.mspeed
        end
end
function move(entity)
    entity.dirX = 0
    entity.dirY = 0
    
    if entity == Player then
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
    
    else
        btns = {0,1,2,3}
        rndbtn = rnd(btns)
        if rndbtn == 0 then
                entity.sprite = 64
                entity.dirX = -1
            end
        
            if rndbtn == 1 then
                entity.sprite = 65
                entity.dirX = 1
            end
        
            if rndbtn == 2 then
                entity.sprite = 80
                entity.dirY = -1
            end
        
            if rndbtn == 3 then
                entity.sprite = 81
                entity.dirY = 1
            end
        
    end
    MoveAndCollision(entity, entity.dirX, entity.dirY)
end

function draw(entity)
    -- Zeichne den Spieler basierend auf der Blickrichtung
    spr(entity.sprite, entity.posX, entity.posY)
end
----------------Portal-----------------








-----------------Boss------------------



-----------------Camera----------------



__gfx__
008880000008880000088000000880000008880077777777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0088880000888800008888000088880000088c0007777777777777777777777777777777777777777777777777777777bb000bbbbbbbbbbbbbbbbbbbbbbbbbbb
00cc88000088cc0000888800008cc80000888c0007777777777777777777777777777777777777777777777777777777b00000bbbbbbbbbbbbbbbbbbbbbbbbbb
00cc88000088cc0000888800008cc8000088880007777777777777777777777777777777777777777777777777777777000000bbbbbbbbbbbbbbbbbbbbbbbbbb
008888000088880000888800008888000088880007777777777777777777777777777777777777777777777777777777000000bbbbbbbbbbbbbbbbbbbbbbbbbb
008888000088880000888800008888000088880000777777777777777777777777777777777777777777777777777777bbb000bbbbbbbbbbbbbbbbbbbbbbbbbb
008888000088880000888800008888000008800000777777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
008800000000880000080000000800000008800000077777777777777777777777777777777777777777777777777777bbbbb00bbbbbbbbbbbbbbbbbbbbbbbbb
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
888088888888088888888888888888888888888888888888000000000000000000000000000000000000000033f77733333b3b33b33333b3333333b333555533
8808888888888088888888888888888888888888888888880000000000000000000000000000000000000000f7cccc73b333b3b33333333b3333333355554453
80888888888888088888888888888888888888888888888800000000000000000000000000000000000000007cccccc73333b333333333333333333355445445
08888888888888808888888888888888888888888888888800000000000000000000000000000000000000007cccccc73b3b333b333333333333333355454445
08888888888888808888888888888888888888888888888800000000000000000000000000000000000000007cccccc7b333333333b3b3333333333354544455
80888888888888088888888888888888888888888888888800000000000000000000000000000000000000007cccccf333b33b3b333b33333333333354545555
880888888888808888888888888888888888888888888888000000000000000000000000000000000000000037cccf33b33333b333333b333333b33355445455
88808888888808888888800000088888888888888888888800000000000000000000000000000000000000003377f333333b333b33333333333b333355555555
88800888888888888888800000008888888888888888888800000000000000000000000000000000000000003333333355555555555555555555555535555553
880880888888888888800000000088888888888888888888000000000000000000000000000000000000000033ffffff55555555555555555555555554454445
80888808888888888880000000008888888888888888888800000000000000000000000000000000000000003ff7f77735555553355555533555555354554445
08888880888888888880000000088888888888888888888800000000000000000000000000000000000000003ff77ccc33555533335555333355553355544445
88888888088888808800088800888888888888888888888800000000000000000000000000000000000000003f77cccc33333333333333333333333355444455
88888888808888088000888800888888888888888888888800000000000000000000000000000000000000003f7ccccc33333333333333333333333354444545
88888888880880888008888000888888888888888888888800000000000000000000000000000000000000003f7cccccb33333b333333b333333333355444445
88888888888008888008880008000888888888888888888800000000000000000000000000000000000000003f7ccccc333b333b333333333333333355555555
00000000000000008000000000000088888888888888888800000000000000000000000000000000000000003333333333333333333333333333333355555555
0000000000000000880000080008000088888888888888880000000000000000000000000000000000000000ffffffff33333333333333333333333355454445
00000000000000008888888800888800088888888888888800000000000000000000000000000000000000007777777733333333333333333333333354444455
0000000000000000888888880000880008008888888888880000000000000000000000000000000000000000ccc77ccc333fff33333333333333333354444455
0000000000000000888888888000000080000008888888880000000000000000000000000000000000000000cccccccc3ffffff333f333333333ff3354554555
0000000000000000888888888800000080000008888888880000000000000000000000000000000000000000ccccccccfccccccf3ffffff33ffffff354445445
0000000000000000888888888888888888008888888888880000000000000000000000000000000000000000ccccccccccccccccfccccccffccccccf55444445
0000000000000000888888888888888888000888000088880000000000000000000000000000000000000000cccccccccccccccccccccccccccccccc55555555
00000000000000008888888888888880000008880000888800000000000000000000000000000000000000000000000000000000000000000000000055544555
00000000000000008888888888888880000088880088888800000000000000000000000000000000000000000000000000000000000000000000000055445544
00000000000000008888888888888888888888880008888800000000000000000000000000000000000000000000000000000000000000000000000055555545
00000000000000008888888888888888888888880008888800000000000000000000000000000000000000000000000000000000000000000000000055555555
00000000000000008888888888888888888800000008888800000000000000000000000000000000000000000000000000000000000000000000000044555455
00000000000000008888888888888888888800000888888800000000000000000000000000000000000000000000000000000000000000000000000055544455
00000000000000008888888888888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000055445554
00000000000000008888888888888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000055555545
