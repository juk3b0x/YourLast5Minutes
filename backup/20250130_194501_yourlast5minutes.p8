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
                col = 0 --colors[0]
            elseif value >= 2 and value < 4 then
                col = 1 --colors[1]
            elseif value >= 4 and value < 6 then
                col = 2 --colors[2]
            elseif value >= 6 and value < 8 then
                col = 3 --colors[3]
            else col = 4 end--colors[4]
            mset(x,y,col + 75)
        end
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
ccccccccccccccccccc88ccccccccccc7777777777777777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cc8cccccccccc8cccc8cc8cccccccccc7777777007777777777777777777777777777777777777777777777777777777bb000bbbbbbbbbbbbbbbbbbbbbbbbbbb
c8cccccccccccc8cc8cccc8ccccccccc7777777007777777777777777777777777777777777777777777777777777777b00000bbbbbbbbbbbbbbbbbbbbbbbbbb
8cccccccccccccc8cccccccccccccccc7777777007777777777777777777777777777777777777777777777777777777000000bbbbbbbbbbbbbbbbbbbbbbbbbb
8cccccccccccccc8cccccccccccccccc7777770007777777777777777777777777777777777777777777777777777777000000bbbbbbbbbbbbbbbbbbbbbbbbbb
c8cccccccccccc8cccccccccc8cccc8c7777770000777777777777777777777777777777777777777777777777777777bbb000bbbbbbbbbbbbbbbbbbbbbbbbbb
cc8cccccccccc8cccccccccccc8cc8cc7777770000777777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccccccccccccccccccc88ccc7777770000077777777777777777777777777777777777777777777777777777bbbbb00bbbbbbbbbbbbbbbbbbbbbbbbb
777700777777777777777007770077777777700070077777777777777777777777777777777777777777777777777777bbbb0000bbbbbbbbbbbbbbbbbbbbbbbb
777700777777777777777000000077777777700770077777777777777777777777777777777777777777777777777777bbb000000bbbbbbbbbbbbbbbbbbbbbbb
777700077777777777777000000077777777700000007777777777777777777777777777777777777777777777777777bbb00bb00bbbbbbbbbbbbbbbbbbbbbbb
777770007777777777777007770077777777000000007777777777777777777777777777777777777777777777777777bbbbbbb00bbbbbbbbbbbbbbbbbbbbbbb
777770000077777777777007770077777777007777007777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
777777700077777777777007777777777777007777007777777777777777777777777777777777777777777777777777bbbbbbbb0000bbbbbbbbbbbbbbbbbbbb
777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777bbbbbbbb00000bbbbbbbbbbbbbbbbbbb
777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777bbbbbbbb00000bbbbbbbbbbbbbbbbbbb
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
8880888888880888888888888888888888888888888888880000000000000000000000000000000000000000ccccccccf7ffff7f3bbb33bb333bb3bb55555555
8808888888888088888888888888888888888888888888880000000000000000000000000000000000000000cccccccc7fff77ffbbb3bbbb3bb3333355554455
8088888888888808888888888888888888888888888888880000000000000000000000000000000000000000ccccccccffff7fffbbbbbbbbb33b3bbb55445445
0888888888888880888888888888888888888888888888880000000000000000000000000000000000000000ccccccccffffffff33bbb33b3b3bb33355454445
0888888888888880888888888888888888888888888888880000000000000000000000000000000000000000ccccccccffff77ffbbbb33bb3333bb3b54544455
8088888888888808888888888888888888888888888888880000000000000000000000000000000000000000cccccccc77f77fffbbbbbbbb3b33333354545555
8808888888888088888888888888888888888888888888880000000000000000000000000000000000000000cccccccc7f7ffff7b33bbbb33b3bb33b55445455
8880888888880888888880000008888888888888888888880000000000000000000000000000000000000000ccccccccfffff77fb3bbbb3bb3333bb355555555
88800888888888888888800000008888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
88088088888888888880000000008888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
80888808888888888880000000008888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880888888888880000000088888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888088888808800088800888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888808888088000888800888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888880880888008888000888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888008888008880008000888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008000000000000088888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008800000800080000888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888800888800088888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888800008800080088888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888880000000800000088888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888000000800000088888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888880088888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888880008880000888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888880000008880000888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888880000088880088888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888888888880008888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888888888880008888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888888800000008888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888888800000888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888888888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010a00001f44618000187000f50000000000000c040000000c04000000187001c50000000000000c040000000c04000000187000c0001c500000000c040000000c040000001870000000000001c5000c04000000
000f00000505004050040500405004050040500405004050040500405004050040500705007050040500405004050040500405004050040500405004050020500205004050050500705007050070500705007050
