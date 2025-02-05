pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

--#include dsa.lua

-------------Varaibles----------------
-------------Map-Vars-----------------
m_size = 129
roughness = flr(rnd(3)) -1
grid = {}
projectiles = {}
stats_active = false
selected_option = 1
frame_counters = {}
timer = 5*60*30
initalTimeout = 5*30
lastCamX = 64
lastCamY = 64
level = 0
-------------Player-Vars--------------
cost_mspeed = 250
cost_aspeed = 200
cost_range = 150
cost_dmg = 150
cost_hp = 100
dead = 0
-------------Mob-Vars-----------------
mobs = {}
initialMobs     = 10
m_b_dmg         = 8
m_b_hp          = 20
m_b_mspeed      = 16
m_b_aspeed      = 1
m_b_range       = 32
m_level_modifier= 0.2
-------------Boss-Vars-----------------
boss = {}
b_b_dmg         = 25
b_b_hp          = 1500
b_b_mspeed      = 16
b_b_aspeed      = 1
b_b_range       = 32
b_level_modifier= 0.1
b0ss = {}
-------------Cartridge----------------
function _init()
    init_grid()
    create_map()
    Player:init(10,1,20,250,100,0)
    Portal:init()
    carve_path(Portal.posX, Portal.posY, Player.posX, Player.posY)
    b0ss = Boss:new()
    b0ss:spawn()
    add(boss,b0ss)
    carve_path(b0ss.posX, b0ss.posY, Player.posX, Player.posY)
    set_map()
    spawnWave(initialMobs)
end

function _update()
    if stats_active then
        Player.posX = 64 * 8
        Player.posY = 64 * 8
        cam(Player)
        if dead == 0 then
            menu_controls()
        end
        if dead == 0 and btnp(5) then
            old_player = Player
            stats_active = false
            init_grid()
            create_map()
            Player:init(old_player.dmg,old_player.aspeed,old_player.mspeed, old_player.range, old_player.hp, old_player.gold)
            Portal:init()
            carve_path(Portal.posX, Portal.posY, Player.posX, Player.posY)
            set_map()
            mobs = {}
            projectiles = {}
            boss = {}
            b0ss = Boss:new()
            b0ss:spawn()
            add(boss,b0ss)
            carve_path(b0ss.posX, b0ss.posY, Player.posX, Player.posY)
            level += 1
            cost_update()
            initialMobs += 5
            spawnWave(initialMobs)
            timer = 5*60*30
        end
    else
        Player:update()
        Projectile:update()
        timeUpdate()
        
        if #mobs <= 100 then
            timeAktion(30, 1, function() spawnWave(initialMobs) end)
        end
        Mob:update()
        Boss:update()
        enterPortal()
    end
end

function _draw()
    cls()
    map(0, 0, 0, 0, 128, 64)
    if stats_active then
        draw_menu(Player.posX,Player.posY)
    else
        draw(Player)
        for mob in all(mobs) do
            draw(mob)
        end
        for boss in all(boss) do
            draw(boss)
        end
        draw(Portal)
        for projectile in all(projectiles) do
            draw(projectile)
        end
    end
    updateHearts()
    local Ox, Oy = overlay(Player, 68, 2)
    print("tIME lEFT: "..flr(timer / 30).."s", Ox, Oy , 7)
    Ox, Oy = overlay(Player, 68,12)
    print("lEVEL: "..level+1, Ox,Oy,7)
end

-------------Baum---------------------
Baum = {}
Baum.__index = Baum  -- Set metatable for Baum instances

function Baum:new()
    local self = setmetatable({}, Baum)  -- Create new instance
    self.posX = 0
    self.posY = 0
    self.sprite = 91
    return self
end

function Baum:add(x, y)
    self.posX = x
    self.posY = y
end



-------------Projectiles--------------
Projectile = {}
Projectile.__index = Projectile  -- Set metatable for Projectile instances

function Projectile:new(sender)
    local self = setmetatable({}, Projectile)  -- Create new instance
    self.dmg = sender.dmg
    self.range = 100
    self.mspeed = 100
    self.posX = 0
    self.posY = 0
    self.dirX = 1
    self.dirY = 0
    self.sprite = 12
    self.spawnpoint = {0,0}
    self.sender = sender
    self:spawn(sender)
    return self
end

function Projectile:move()
    MoveAndCollision(self, self.dirX, self.dirY)
end

function Projectile:die()
    despawn(self)
end

function Projectile:rangeUpdate()
    if self.range <= 0 then
        despawn(self)
    else self.range -= 1 end
end

function Projectile:update()
    for projectile in all(projectiles) do
        projectile:rangeUpdate()
            projectile:move()

        projectileHit(projectile)
    end
end

function Projectile:spawn(sender)
    self.mspeed = sender.aspeed
    if sender.sprite == 0 then
        self.spawnpoint[1] = sender.posX - 4
        self.spawnpoint[2] = sender.posY
        self.sprite = 12
        self.dirX = -1
        self.dirY = 0
    elseif sender.sprite == 1 then
        self.spawnpoint[1] = sender.posX + 4
        self.spawnpoint[2] = sender.posY
        self.sprite = 13
        self.dirX = 1
        self.dirY = 0
    elseif sender.sprite == 2 then
        self.spawnpoint[1] = sender.posX
        self.spawnpoint[2] = sender.posY - 4
        self.sprite = 14
        self.dirY = -1
        self.dirX = 0
    elseif sender.sprite == 3 then
        self.spawnpoint[1] = sender.posX
        self.spawnpoint[2] = sender.posY + 4
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
    mspeed = 20,
    hspeed = 1,
    range = 64,
    hp = 100,
    gold = 100,
    posX = 0,
    posY = 0,
    dirX = 1,
    dirY = 1,
    sprite = 0,
    spawn_area = "tl",

    init = function(self, dmg,aspeed,mspeed,range,hp,gold)
        self.dmg = dmg
        self.aspeed = aspeed
        self.mspeed = mspeed
        self.range = range
        self.hp = hp
        self.gold = gold
        local zahler = 0
        while spawnPointWall(Player) and zahler <= 100 do
            self.spawn_area = rnd({"tl","tr","bl","br"})
            if self.spawn_area == "tl" then
                self.posX = flr(10+rnd(10)) *8
                self.posY = flr(10+rnd(10)) *8
            elseif self.spawn_area == "tr" then
               self.posX = flr(107 + rnd(10)) * 8
               self.posY = flr(10 + rnd(10)) * 8
            elseif self.spawn_area == "bl" then
               self.posX = flr(10 + rnd(10)) * 8
               self.posY = flr(43 + rnd(10)) * 8
            elseif self.spawn_area == "br" then
                self.posX = flr(107 + rnd(10)) * 8
                self.posY = flr(43 + rnd(10)) * 8
            end
            zahler += 1
        end
        set_grid((self.posX/8) +1, (self.posY/8) +1, 5 )
    end,

    update = function(self)
        timeAktionSpeed(self.mspeed,function() move(self) end)
        timeAktionSpeed(self.aspeed,function() attack(self) end)
        timeAktionSpeed(self.hspeed,function() projectileHit(self) end)
        cam(self)
        if self.hp <= 0 then
            dead = 1
            stats_active = true
        end
    end
}
-----------------Mob-------------------
Mob = {}
Mob.__index = Mob  -- Set metatable for Mob instances

function Mob:new()
    local self  = setmetatable({}, Mob)  -- Create new instance
    self.dmg    = m_b_dmg + (m_b_dmg * m_level_modifier)
    self.mspeed = m_b_mspeed + (m_b_mspeed * m_level_modifier)
    self.aspeed = m_b_aspeed + (m_b_aspeed * m_level_modifier)
    self.range  = m_b_range + (m_b_range * m_level_modifier)
    self.hp     = m_b_hp + (m_b_hp * m_level_modifier)
    self.posX = 0
    self.posY = 0
    self.dirX = 1
    self.dirY = 0
    self.sprite = 64
    self.spawnpoint = {-1, -1}
    self.patrolPoint1 = {flr(rnd(128)*8), flr(rnd(64)*8)}
    self.patrolPoint2 = {flr(rnd(128)*8), flr(rnd(64)*8)}
    self.targetPoint = self.patrolPoint1
    self.moveRand = rnd(15,30)
    self.moveRand2 = rnd(90,120)
    return self
end


function Mob:update()
     for mob in all(mobs) do
        timeAktionSpeed(mob.mspeed,function() mob:chase(Player) end)
        projectileHit(mob)
        timeAktionSpeed(mob.aspeed,function() meeleeAttack(mob) end)
     end
end


function Mob:die()
    Player.gold += 50
    despawn(self)
end

function Mob:spawn()
    if self.spawnpoint[1] == -1 and self.spawnpoint[2] == -1 then
    while spawnPointWall(self) do
            self.spawnpoint[1] = flr(rnd(128*8))
            self.spawnpoint[2] = flr(rnd(64*8))
            self.posX = self.spawnpoint[1]
            self.posY = self.spawnpoint[2]
    end
    end
end

function Mob:patrol()
    local dx = self.targetPoint[1] - self.posX
    local dy = self.targetPoint[2] - self.posY

    self.dirX = sgn(dx)
    self.dirY = sgn(dy)
    
    move(self)

    if abs(dx) <= 1 and abs(dy) <= 1 then
        if self.targetPoint == self.patrolPoint1 then
            self.targetPoint = self.patrolPoint2
        else
            self.targetPoint = self.patrolPoint1
        end
    end
end

function Mob:chase(entity)
    local dx = entity.posX - self.posX
    local dy = entity.posY - self.posY
    local distance = sqrt(dx * dx + dy * dy)
    self.dirX = sgn(dx)
    self.dirY = sgn(dy)

    if timer % 120 > 30  then
        if distance < self.range  then
             move(self)
        else
             self:patrol()
         end
    elseif timer % 120 < 30 then
        self:patrol()
    end
end

-----------------Boss-------------------
Boss = {}
Boss.__index = Boss  -- Set metatable for Mob instances

function Boss:new()
    local self = setmetatable({}, Boss)  -- Create new instance
    self.dmg    = b_b_dmg + (b_b_dmg * b_level_modifier)
    self.mspeed = b_b_mspeed + (b_b_mspeed * b_level_modifier)
    self.aspeed = b_b_aspeed + (b_b_aspeed * b_level_modifier)
    self.range  = b_b_range + (b_b_range * b_level_modifier)
    self.hp     = b_b_hp + (b_b_hp * b_level_modifier)
    self.posX = 0
    self.posY = 0
    self.dirX = 1
    self.dirY = 0
    self.sprite = 66
    self.spawnpoint = {-1, -1}
    self.patrolPoint1 = {flr(rnd(128)*8), flr(rnd(64)*8)}
    self.patrolPoint2 = {flr(rnd(128)*8), flr(rnd(64)*8)}
    self.targetPoint = self.patrolPoint1
    self.moveRand = rnd(15,30)
    self.moveRand2 = rnd(90,120)
    return self
end


function Boss:update()
     for b in all(boss) do
        timeAktionSpeed(b.mspeed,function() b:chase(Player) end)
        projectileHit(b)
        timeAktionSpeed(b.aspeed,function() meeleeAttack(b) end)
     end
end


function Boss:die()
    Player.gold += 1500
    despawn(self)
end

function Boss:spawn()
    if Player.spawn_area == "tl" then
            self.posX = flr((64 + rnd(60))) *8
            self.posY = flr((32 + rnd(28))) *8
        elseif Player.spawn_area == "tr" then
            self.posX = flr((m_size - 1 - 64 - rnd(60))) *8
            self.posY = flr((32 + rnd(28))) *8
        elseif Player.spawn_area == "bl" then
            self.posX = flr((64 + rnd(60))) *8
            self.posY = flr((((m_size-1)/2) - 32 - rnd(28))) *8
        elseif Player.spawn_area == "br" then
            self.posX = flr((m_size - 1 - 64 - rnd(60))) *8
            self.posY = flr((((m_size-1)/2) - 32 - rnd(28))) *8
    end
    if spawnPointWall(self) then
         self:spawn()
    end
end

function Boss:patrol()
    local dx = self.targetPoint[1] - self.posX
    local dy = self.targetPoint[2] - self.posY

    self.dirX = sgn(dx)
    self.dirY = sgn(dy)
    
    move(self)

    if abs(dx) <= 1 and abs(dy) <= 1 then
        if self.targetPoint == self.patrolPoint1 then
            self.targetPoint = self.patrolPoint2
        else
            self.targetPoint = self.patrolPoint1
        end
    end
end

function Boss:chase(entity)
    local dx = entity.posX - self.posX
    local dy = entity.posY - self.posY
    local distance = sqrt(dx * dx + dy * dy)
    self.dirX = sgn(dx)
    self.dirY = sgn(dy)

    if timer % 120 > 30  then
        if distance < self.range  then
             move(self)
        else
             self:patrol()
         end
    elseif timer % 120 < 30 then
        self:patrol()
    end
end


----------------Stats------------------
function draw_menu(x_center, y_center)
    if dead == 0 then
        -- Solid menu background (covering 64x64 pixels)
        x_start = x_center - 56
        y_start = y_center - 104
        x_end = x_center + 56
        y_end = y_center - 16
        rectfill(x_start,y_start,x_end,y_end, 0) -- Black background
        rect(x_start,y_start,x_end,y_end, 7) -- White border

        -- Menu title
        print("player stats", x_start + 5, y_start+2, 7)

        -- Stats list with click areas
        print((selected_option == 1 and ">" or " ").." Healthpoints: "..flr(Player.hp).."("..cost_hp..")", x_start+2, y_start+10, 7)
        print((selected_option == 2 and ">" or " ").." Damage: "..Player.dmg.."("..cost_dmg..")", x_start+2, y_start+18, 7)
        print((selected_option == 3 and ">" or " ").." Attack-Speed: "..Player.aspeed.."("..cost_aspeed..")", x_start+2, y_start+26, 7)
        print((selected_option == 4 and ">" or " ").." Movement-Speed: "..Player.mspeed.."("..cost_mspeed..")", x_start+2, y_start+34, 7)
        print((selected_option == 5 and ">" or " ").." Range: "..Player.range.."("..cost_range..")", x_start+2, y_start+42, 7)

        -- Points display
        print("Gold: "..Player.gold, x_start+5, y_start+50, 7)
    else
        -- Solid menu background (covering 64x64 pixels)
        x_start = x_center - 56
        y_start = y_center - 104
        x_end = x_center + 56
        y_end = y_center - 16
        rectfill(x_start,y_start,x_end,y_end, 0) -- Black background
        rect(x_start,y_start,x_end,y_end, 7) -- White border
        print("gAME oVER", x_start + 32, y_start+2, 7)
        print("yOU died at lEVEL: "..level+1, x_start+8, y_start+10, 7)
        print("pRESS ctrl+r to restart", x_start+8, y_start+18, 7)
    end
end

function menu_controls()
    -- Move selection up/down
    if btnp(2) then selected_option = max(1, selected_option - 1) end
    if btnp(3) then selected_option = min(5, selected_option + 1) end

    -- Increase stat if clicked or if "O" button (btn(4)) is pressed
    if btnp(4) and Player.gold > 0 then
        if selected_option == 1 and Player.gold >= cost_hp  then
            Player.hp       += 1
            Player.gold     -= cost_hp
        elseif selected_option == 2 and Player.gold >= cost_dmg then
            Player.dmg      += 1
            Player.gold     -= cost_dmg
        elseif selected_option == 3 and Player.gold >= cost_aspeed then
            Player.aspeed   += 1
            Player.gold     -= cost_aspeed
        elseif selected_option == 4 and Player.gold >= cost_mspeed then
            Player.mspeed   += 1
            Player.gold     -= cost_mspeed
        elseif selected_option == 5  then
            Player.range    += 1
            Player.gold     -= cost_range
        end
    end
end

function updateHearts()
    if Player.hp < 20 then
        spr(33, overlay(Player,1 , 1))
    else
        spr(32, overlay(Player,1 , 1))
    end
    if Player.hp < 40 then
        spr(33, overlay(Player,10 , 1))
    else
        spr(32, overlay(Player,10 , 1))
    end
    if Player.hp < 60 then
        spr(33, overlay(Player,19 , 1))
    else
        spr(32, overlay(Player,19 , 1))
    end
    if Player.hp < 80 then
        spr(33, overlay(Player,28 , 1))
    else
        spr(32, overlay(Player,28 , 1))
    end
    if Player.hp < 100 then
        spr(33, overlay(Player,37 , 1))
    else
        spr(32, overlay(Player,37 , 1))
    end
end

-----------------MAP-------------------
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
    border(m_size-1)
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
function border(p)
    for x = 1, p do
        for y = 1, 64 do
            if x == 1 or x == p or y == 1 or y == 64   then
                set_grid(x, y, 15)
            end
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

    local pX = flr(entity.posX / 8)
    local pY = flr(entity.posY / 8)
    local gridX = pX + moveX
    local gridY = pY + moveY


        pX = flr(entity.posX / 8)
        pY = flr(entity.posY / 8)
        gridX = pX + moveX
        gridY = pY + moveY

        if (entity.posX % 8 == 0 and
            get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4 and
            get_level(gridX, pY + 1) > 0 and get_level(gridX, pY + 1) < 4) or
            entity.posX % 8 != 0 or
            (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4) then
                entity.posX = entity.posX + moveX
        end

        pX = flr(entity.posX / 8 + 1)
        gridX = pX + moveX

        if (entity.posY % 8 == 0 and
            get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4 and
            get_level(pX + 1, gridY) > 0 and get_level(pX + 1, gridY) < 4) or
            entity.posY % 8 !=  0 or
            (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4) then
                entity.posY = entity.posY + moveY
        end

end


function MoveAndCollision(entity, moveX, moveY, size)

    if size == nil then size = 1 end

    local pX = flr(entity.posX / 8)
    local pY = flr(entity.posY / 8)
    local gridX = pX + moveX
    local gridY = pY + moveY
    local boolX = false
    local boolY = false
    local i = 0

    while i <= size - 1 do
         pX = flr(entity.posX / 8 + i)
         pY = flr(entity.posY / 8 + i)
         gridX = pX + moveX
         gridY = pY + moveY

        if (entity.posX % 8 == 0 and
        get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4 and
        get_level(gridX, pY + 1) > 0 and get_level(gridX, pY + 1) < 4) or
        entity.posX % 8 != 0 or
        (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4) then
            boolX = true
        else
            boolX = false
            break
        end
        if size != 0 then
            pX = flr(entity.posX / 8)
            pY = flr(entity.posY / 8 + i)
            gridX = pX + moveX
            gridY = pY + moveY

            if (entity.posX % 8 == 0 and
            get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4 and
            get_level(gridX, pY + 1) > 0 and get_level(gridX, pY + 1) < 4) or
            entity.posX % 8 != 0 or
            (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4) then
                boolX = true
            else
                boolX = false
                break
            end
            pX = flr(entity.posX / 8 + i)
            pY = flr(entity.posY / 8)
            gridX = pX + moveX
            gridY = pY + moveY

            if (entity.posX % 8 == 0 and
            get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4 and
            get_level(gridX, pY + 1) > 0 and get_level(gridX, pY + 1) < 4) or
            entity.posX % 8 != 0 or
            (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(gridX, pY) > 0 and get_level(gridX, pY) < 4) then
                boolX = true
            else
                boolX = false
                break
            end
        end
        i += 1
    end
    
    if boolX then
        entity.posX = entity.posX + moveX
    end
        local i = 0

    while i <= size - 1 do    
        pX = flr(entity.posX / 8 + i)
        pY = flr(entity.posY / 8)
        gridX = pX + moveX
        gridY = pY + moveY

        if (entity.posY % 8 == 0 and
            get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4 and
            get_level(pX + 1, gridY) > 0 and get_level(pX + 1, gridY) < 4) or
            entity.posY % 8 !=  0 or
            (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4) then
                boolY = true
            else
                boolY = false
                break
        
        end
        if size != 0 then
            pX = flr(entity.posX / 8)
            pY = flr(entity.posY / 8 + i)
            gridX = pX + moveX
            gridY = pY + moveY

            if (entity.posY % 8 == 0 and
                get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4 and
                get_level(pX + 1, gridY) > 0 and get_level(pX + 1, gridY) < 4) or
                entity.posY % 8 !=  0 or
                (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4) then
                    boolY = true
                else
                    boolY = false
                    break
            
            end
            pX = flr(entity.posX / 8 + i)
            pY = flr(entity.posY / 8 + i)
            gridX = pX + moveX
            gridY = pY + moveY

            if (entity.posY % 8 == 0 and
                get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4 and
                get_level(pX + 1, gridY) > 0 and get_level(pX + 1, gridY) < 4) or
                entity.posY % 8 !=  0 or
                (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4) then
                    boolY = true
                else
                    boolY = false
                    break
            end
        end
        i += 1
    end

    if boolY then
        entity.posY = entity.posY + moveY
    end
end

----------------Utility------------------------------------
function carve_path(originX, originY, destinationX, destinationY)
    local non_blocking_tiles = {76, 77, 78, 124, 125, 126}
    originX, originY, destinationX, destinationY = flr(originX/8), flr(originY/8), flr(destinationX/8), flr(destinationY/8)
    while originX ~= destinationX or originY ~= destinationY do
        local dx = destinationX - originX
        local dy = destinationY - originY
        local new_x, new_y

        -- Move in the best direction first
        if abs(dx) > abs(dy) then
            new_x, new_y = originX + sgn(dx), originY  -- Horizontal move
        else
            new_x, new_y = originX, originY + sgn(dy)  -- Vertical move
        end

        -- Ensure we are making progress
        if is_within_bounds(new_x, new_y) then

            local tile = get_level(new_x, new_y)

            -- If the tile is blocked, replace it
            if tile == 0 or tile == 4 then
                set_grid(new_x +1, new_y +1, 3)
            end

            -- Move to the new position
            originX, originY = new_x, new_y
        end

        -- Safety check: if the function stalls, break to avoid infinite loop
        if (dx == 0 and dy == 0) then
            break
        end
    end
end

function is_within_bounds(x, y)
    return x >= 0 and x < (m_size - 1) and y >= 0 and y < ((m_size-1)/2)
end

function spawnWave(count)
    for i = 1, count do
        mob = Mob:new()
        mob:spawn()
        add(mobs, mob)
    end
end

function spawnBoss()
    b = Boss:new()
    b:spawn()
    add(boss, b)
end

function spawnBaum(x, y)
    b = Baum:new(x, y)
    add(Baum, b)
end



function projectileHit(entity)
    for projectile in all(projectiles) do
        if flr(projectile.posX / 8) == flr(entity.posX / 8) and         //entity.x stimmt れもberein
            flr(projectile.posY / 8) == flr(entity.posY / 8) and not    //entity.y stimmt れもberein
            (getmetatable(entity) == getmetatable(entity.sender)) and not//mobs schieれかen nicht ausversehen auf mobs
            (entity == entity.sender) and not
            (getmetatable(entity) == Projectile) then                              //player kann nicht durch seine eigenen schれもsse verletzt werden
                receivedmg(entity, projectile.dmg)
                if getmetatable(entity) == Boss then
                    projectile.range = 0
                else
                    projectile.range = flr(projectile.range / 2)
                end
                
        end
        if getmetatable(entity) == Boss then
           if (flr(projectile.posX / 8) == flr(entity.posX / 8) + 1) and (flr(projectile.posY / 8) == flr(entity.posY / 8))
           or (flr(projectile.posX / 8) == flr(entity.posX / 8)) and (flr(projectile.posY / 8) == flr(entity.posY / 8) + 1)
           or (flr(projectile.posX / 8)  == flr(entity.posX / 8) + 1) and (flr(projectile.posY / 8) == flr(entity.posY / 8) + 1) 
           and not (getmetatable(entity) == getmetatable(entity.sender)) 
           and not (entity == entity.sender) 
           and not (getmetatable(entity) == Projectile) then
            receivedmg(entity, projectile.dmg)
            projectile.range = 0
           end       
        end
    end
end

function enterPortal()
    portal_coords = {{flr(Portal.posX/8),flr(Portal.posY/8)}, {flr(Portal.posX/8) +1, flr(Portal.posY/8)}, {flr(Portal.posX/8), flr(Portal.posY/8) +1}, {flr(Portal.posX/8) +1, flr(Portal.posY/8) +1}}
    for coord in all(portal_coords) do
        if coord[1] == flr(Player.posX/8) and coord[2] == flr(Player.posY/8) then
            for mob in all(mobs) do
                despawn(mob)
            end
            for projectile in all(projectiles) do
                despawn(projectile)
            end
            stats_active = true
            return
        end
    end
end

function move(entity)
    local size = 1
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
    
        elseif getmetatable(entity) == Mob then
            updateSprite(entity, entity.dirX, entity.dirY)
            
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
    
        elseif getmetatable(entity) == Boss then
            if entity.dirX == -1 then
                entity.sprite = 66
            elseif entity.dirX == 1 then
                entity.sprite = 68
            elseif entity.dirY == -1 then
                entity.sprite = 98
            elseif entity.dirY == 1 then
                entity.sprite = 100
            end
            size = 2
        end
    
        MoveAndCollision(entity, entity.dirX, entity.dirY, size)
    end
    

function attack(sender)
    if sender == Player then
        if btn(4) then
            add(projectiles, Projectile:new(sender))
        end
    end
end

function draw(entity)
    if entity == Portal or getmetatable(entity) == Boss  then
        spr(entity.sprite, entity.posX, entity.posY, 2, 2)
    else
    -- Zeichne den Spieler basierend auf der Blickrichtung
    spr(entity.sprite, entity.posX, entity.posY)
    end
end

function despawn(entity)
    if getmetatable(entity) == Projectile then
        del(projectiles, entity)
    end
    if getmetatable(entity) == Mob then
        del(mobs, entity)
    end
    if getmetatable(entity) == Boss then
        del(boss, entity)
    end
end

function receivedmg(entity,dmg)
    entity.hp -= dmg
    if entity ~= Player and entity.hp <= 0 then
        entity:die()
    end
end

function meeleeAttack(mob)
        if flr(mob.posX / 8) == flr(Player.posX / 8) and
            flr(mob.posY / 8) == flr(Player.posY / 8) then
                receivedmg(Player, mob.dmg)
        end
end


function frameAktion(id, fps)
    if fps < 1 then fps = 1 end -- Verhindert Division durch 0
    local interval = 30 / fps -- Berechnet, alle wie viele Frames die Aktion ausgefれもhrt wird

    -- Initialisiere den Counter fれもr diese ID, falls nicht vorhanden
    if not frame_counters[id] then
        frame_counters[id] = 0
    end

    -- Counter hochzれさhlen und prれもfen
    frame_counters[id] += 1
    if frame_counters[id] >= interval then
        frame_counters[id] = 0
        return true
    end
    return false
end

function timeAktion(jedeXsekunde, anzahl, aktion)
    if timer > 0 and timer != lastTimer then
        if timer % (30 * jedeXsekunde) == 0 then
            for i = 1, anzahl do
                aktion()
                lastTimer = timer
            end
        end
    end
end

function timeAktionFrame(jedesXframe, anzahl, aktion)
    if timer > 0 and timer then
        if timer % jedesXframe < 1 then
            for i = 1, anzahl do
                aktion()
            end
        end
    end
end

function timeAktionSpeed(speed, aktion)
    g = 0
    if speed >= 21 then g = 1 end
    frames = 2 / ( g + ( (speed % 21) * 0.1))
    timeAktionFrame(frames,1 + (speed/21), aktion)
end


function timeUpdate()
    if timer > 0 then
        timer -= 1  -- Reduziert den Timer jede Frame
    end
end

function spawnPointWall(e)
    xp = flr(e.posX / 8)
    yp = flr(e.posY / 8)

    -- if xp  == nil or yp == nil then
    --     return true
    if get_level(xp, yp) == 1   then
         return false
    else
        return true
    end
end

function initPlayerField()
    set_grid(Player.posX/8, Player.posY/8, 5)
    mset(Player.posX/8, Player.posY/8, 77)
end

function updateSprite(entity, pX, pY)
    if pY > 0 then
        entity.sprite = 80
    elseif pY <= 0 then
        entity.sprite = 81
    end

    if pX > 0 then
        entity.sprite = 65
    elseif pX <= 0 then
        entity.sprite = 64
    end
end

----------------Menue------------------


----------------Portal-----------------
Portal = {
posX = 0,
posY = 0,
sprite = 70,

init = function(self)
        if Player.spawn_area == "tl" then
            self.posX = flr((64 + rnd(60))) *8
            self.posY = flr((32 + rnd(28))) *8
        elseif Player.spawn_area == "tr" then
            self.posX = flr((m_size - 1 - 64 - rnd(60))) *8
            self.posY = flr((32 + rnd(28))) *8
        elseif Player.spawn_area == "bl" then
            self.posX = flr((64 + rnd(60))) *8
            self.posY = flr((((m_size-1)/2) - 32 - rnd(28))) *8
        elseif Player.spawn_area == "br" then
            self.posX = flr((m_size - 1 - 64 - rnd(60))) *8
            self.posY = flr((((m_size-1)/2) - 32 - rnd(28))) *8
        end
    if spawnPointWall(self) then
         self:init()
    end
end
}







-----------------Boss------------------



-----------------Camera----------------

function cam(entity)
    local x = entity.posX - 64
    local y = entity.posY - 64
    if entity.posX/8 > m_size - 8 then
        x = m_size * 7
    end
    if entity.posX/8 < 8 then
        x = 0
    end
    if entity.posY/8 > m_size/2 - 8 then
        y = m_size/2 * 6
    end
    if entity.posY/8 < 8 then
        y = 0
    end
    camera(x,y)

end

function overlay(entity,offsetX ,offsetY)
    local x = entity.posX - 64
    local y = entity.posY - 64
    if entity.posX/8 > m_size - 8 then
        x = m_size * 7
    end
    if entity.posX/8 < 8 then
        x = 0
    end
    if entity.posY/8 > m_size/2 - 8 then
        y = m_size/2 * 6
    end
    if entity.posY/8 < 8 then
        y = 0
    end
    return x + offsetX, y + offsetY

end

function cost_update()
    cost_mspeed = flr(cost_mspeed + (cost_mspeed * 2 * m_level_modifier))
    cost_aspeed = flr(cost_aspeed + (cost_aspeed * 2 * m_level_modifier))
    cost_range = flr(cost_range + (cost_range * 2 * m_level_modifier))
    cost_dmg = flr(cost_dmg + (cost_dmg * 2 * m_level_modifier))
    cost_hp = flr(cost_hp + (cost_hp * 2 * m_level_modifier))
end
---------------------------------------



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
001001000010010077777777777777777777777777007777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
018118100161161077777777777777777777777777007777777777777777777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbbb00bbbbbbbbb
188877811666776177777777777777777777777770007777777777777777777777777777777777777777770077777777bbbbbbbbbbbbbbbbbbbbb00bbbbbbbbb
188887811616616177777777777777777777777770007777777777700777777777000000077777777777770007777777bbbbbbbbbbbbbbbbbbb00bbbbbbbbbbb
188888811666666177777000777777777777777770007777777770000077777777000000077777777777770007777777bbbbbbbbbbbbbbbb00000bbbbbbbbbbb
018888100161161077700000777777777777777770007777777700000077777777700077777777777777770000777777bbbbbbbbbbbbbbbb00000bbbbbbbbbbb
001881000016610077700000777777777777777700007777777700777777777777700777777000777777700000777777bbbbbbbbbbbbbbbb000bbbbbbbbbbbbb
000110000001100077700007777777777777777700007777777700777777777777700777700000777777700000077777bbbbbbbbbbbbbbbb00bbbbbbbbbbbbbb
777777777777777777700007777777777777777000007777777700777777777777700777000077777777700070077777bbbbbbbbbbbbbbbbbbbb000bbbbbbbbb
777777777777777777700077777777777777777007007777777700777777777777700777000000777777700070077777bbbbbbbbbbbbbbbbbbb0000bbbbbbbbb
777777777777777777700077777777777777770007000777777700777777777777700777000000777777700070077777bbbbbbbbbbbbbbbbbbb0000bbbbbbbbb
777777777777777777700000777777777777770070000077777700077777777777700777000777777777700770000777bbbbbbbbbbbbbbbbbbb0000bbbbbbbbb
777777777777777777700000007777777777700070000077777770077777777777700777700077777777700777000777bbbbbbbbbbbbbbbbbbb0000bb000bbbb
777777777777777777700770007777777777700777700777777770007777777777700777770000777777777777777777bbbbbbbbbbbbbbbbbbb000bbb000bbbb
777777777777777777777777007777777777000777777777777777000077777777700777777000777777777777777777bbbbbbbbbbbbbbbbbbb0000bb000bbbb
777777777777777777777777777777777777007777777777777777700077777777777777777777777777777777777777bbbbbbbbbbbbbbbbbbbb0000bb000bbb
008888000088880000000888888000000000088888800000008040000004080000000000000000000000000033355533333b3b33b33333b33333333333555533
07e77880088777e000078777777880000008877787787000800004044040000800000000000000000000000033355533b333b3b33333333b3333333355554453
7777e788887e7777007777777887880000887777ee7777000400004ee4000040000000000000000000000000333455333333b333333333333333333355445445
6999777887779997077777ee8e7777800887777777777770040004eeee400040000000000000000000000000333445333b3b333b333333333333333355454445
691997e88e799197077777e777777880088887777777777000404ee22ee4040000000000000000000000000033344433b333333333b3b3333333333354544455
6911977886e91197778887777777888888878877777888770004ee2222ee40000000000000000000000000003344443333b33b3b333b33333333333354545555
0699977006699970788888777777778888777e77778888874804e828828e408400000000000000000000000033444433b33333b333333b333333333355445455
0066670000666700781778777777778888777777778177874004e288882e400400000000000000000000000033444433333b333b333333333333333355555555
007777000088880078111887777ee888887777e7788111870404e228822e404000000000000000001100101133aaaa3355555555555555555555555535555553
0e7887e0087e7780681111877777777888678e77781111870044e228822e440000005000000000000022ee003aaaaaa355555555555555555555555554454445
7782287777799777668111887777778888668777881118770004e828828e40000053450000000000122e2e21aaaaaaaa35555553355555533555555354554445
788e287e77999977068811887777778008688677881188708004e282282e4008054553400000000002e22220999aaaaa33555533335555333355553355544445
778e888777900977066888886e7776800886666688888770004555555555540005355400000000001ee2e2e199999aaa33333333333333333333333355444455
7ee8e87776900977006688866e866800008866e6688877000499999999999940044343500000000002e22e20999999aa33333333333333333333333354444545
077e77e00669977000066666668e800000088ee66666700045555555555555540034450000000000102e220199999999b33333b333333b333333333355444445
007777000066670000000666666000000000066666600000499999999999999400040000000000000101011039999993333b333b333333333333333355555555
00000000000000000000077e77700000000008888880000000000000000000000000000000000000000000000000000000000000000000000000000055555555
0000000000000000000e777ee87e70000008877e7778800000000000000000000000000000000000000000000000000000000000000000000000000055454445
0000000000000000007ee888ee8877000087777e7777780000000000000000000000000000000000000000000000000000000000000000000000000054444455
000000000000000007e7ee888e88877008e777777777778000000000000000000000000000000000000000000000000000000000000000000000000054444455
000000000000000007788e8888e888700777778888777e7080000000000000000000000000000000000000000000000000000000000000000000000054554555
0000000000000000e7888882228887ee7777788888877777e0000000000000000000000000000000000000000000000000000000000000000000000054445445
0000000000000000ee88e22ee288eee777778877188877778e00000e000000000000000000000000000000000000000000000000000000000000000055444445
0000000000000000668882ee22888877e77788771188777eeee0000e000000000000000000000000000000000000000000000000000000000000000055555555
0000000000000000668882e22288887eee778811118877eeeeee00ee000000000000000000000000000000000000000033333393333333333333333355544555
00000000000000006668882ee28eee776677881111887ee7e80eeee000000000000000000000000000000000000000003b3b39a9333333b3332b333355445544
00000000000000006ee88888e888e777666688111188777780000000000000000000000000000000000000000000000033b33393383333333223b3b355555545
000000000000000006668888ee87e77006668811118877700000000000000000000000000000000000000000000000003333333382b333333e33b33355555555
0000000000000000066666ee8877ee70066668888887777000000000000000000000000000000000000000000000000033333333383338333333b33344555455
00000000000000000066666777777e0000666688887777000000000000000000000000000000000000000000000000003393333333338283333bb33355544455
000000000000000000066666e7777000000666666777700000000000000000000000000000000000000000000000000039a933b333333b33b33b333355445554
000000000000000000000666e7700000000006666670000000000000000000000000000000000000000000000000000033933333b3333333b333333b55555545
__gff__
0000000000000000000000008080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000001000000000000000001000001000000010000000000000000000000000000000100000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
