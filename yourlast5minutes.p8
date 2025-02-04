pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

--#include dsa.lua

-------------Varaibles----------------
m_size = 129
roughness = flr(rnd(3)) -1
grid = {}
mobs = {}
projectiles = {}
frame_counters = {}
stats_active = false
selected_option = 1
lastCamX = 64
lastCamY = 64
timer = 5*60*30
initialMobs = 10
costMspeed = 5000
costAspeed = 1000
costRange = 200
costDamage = 200
costHp = 200


-------------Cartridge----------------
function _init()
    init_grid()
    create_map()
    set_map()
    Player:init()

    --Portal:init()
end

function _update()
    if btnp(5) then
        stats_active = not stats_active
    end
    if stats_active then
        menu_controls()

    else
        Player:update()
        Projectile:update()
        timeUpdate()
        if #mobs <= 100 then
            timeAktion(5, 1, function() spawnWave(initialMobs) end)
        end
        Mob:update()
    end
end

function _draw()
    cls()
    map(0, 0, 0, 0, 128, 64)
    if stats_active then
        draw_menu(Player.posX, Player.posY)
    else
        draw(Player)
        for mob in all(mobs) do
            draw(mob)
        end
        draw(Portal)
        for projectile in all(projectiles) do
            draw(projectile)
        end
    end
    updateHearts()
    local Ox, Oy = overlay(Player, 68, 2)
    print("tIME lEFT: "..flr(timer / 30).."s", Ox, Oy , 7)
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
    aspeed = 0.5,
    mspeed = 20,
    hspeed = 1,
    range = 200,
    hp = 100,
    gold = 100,
    posX = 0,
    posY = 0,
    dirX = 1,
    dirY = 1,
    sprite = 0,
    spawn_area = "tl",

    init = function(self)
        self.spawn_area = rnd({"tl","tr","bl","br"})
        while spawnPointWall(Player) do
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
        end
    end,

    update = function(self)
        timeAktionSpeed(self.mspeed,function() move(self) end)
        timeAktionSpeed(self.aspeed,function() attack(self) end)
        timeAktionSpeed(self.hspeed,function() projectileHit(self) end)
        cam(self)
    end
}
-----------------Mob-------------------
Mob = {}
Mob.__index = Mob  -- Set metatable for Mob instances

function Mob:new()
    local self = setmetatable({}, Mob)  -- Create new instance
    self.dmg = 10
    self.mspeed = 10
    self.aspeed = 0.5
    self.range = 300
    self.hp = 100
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
    Player.gold += 10
    despawn(self)
    Player.gold += 10
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

    if abs(dx) > 1 then
        MoveAndCollision(self, sgn(dx), 0)
    end

    if abs(dy) > 1 then
        MoveAndCollision(self, 0, sgn(dy))
    end

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

    if timer % 120 > 30  then
        if distance < self.range  then
            MoveAndCollision(self, sgn(dx), sgn(dy))
        else
             self:patrol()
         end
    elseif timer % 120 < 30 then
        self:patrol()
    end
end


----------------Stats------------------
function draw_menu(x_center, y_center)
    -- Solid menu background (covering 64x64 pixels)
    x_start = x_center - 32
    y_start = y_center - 32
    x_end = x_center + 32
    y_end = y_center + 32
    rectfill(x_start,y_start,x_end,y_end, 0) -- Black background
    rect(x_start,y_start,x_end,y_end, 7) -- White border

    -- Menu title
    print("player stats", x_start + 5, y_start+2, 7)

    -- Stats list with click areas
    print((selected_option == 1 and ">" or " ").." Healthpoints: "..Player.hp, x_start+2, y_start+10, 7)
    print((selected_option == 2 and ">" or " ").." Damage: "..Player.dmg, x_start+2, y_start+18, 7)
    print((selected_option == 3 and ">" or " ").." Attack-Speed: "..Player.aspeed, x_start+2, y_start+26, 7)
    print((selected_option == 4 and ">" or " ").." Movement-Speed: "..Player.mspeed, x_start+2, y_start+34, 7)
    print((selected_option == 5 and ">" or " ").." Range: "..Player.range, x_start+2, y_start+42, 7)

    -- Points display
    print("Gold: "..Player.gold, x_start+5, y_start+50, 7)
end

function menu_controls()
    -- Get mouse input (stat(32) = X, stat(33) = Y, stat(34) = Left Click)
    local mx, my, click = stat(32), stat(33), stat(34)

    -- Move selection up/down
    if btnp(2) then selected_option = max(1, selected_option - 1) end
    if btnp(3) then selected_option = min(5, selected_option + 1) end

    -- Increase stat if clicked or if "O" button (btn(4)) is pressed
    if (click == 1 or btnp(4)) and Player.gold > 0 then
        if selected_option == 1 or (mx >= 38 and mx <= 90 and my >= 45 and my <= 53) then
            Player.hp += 1
        elseif selected_option == 2 or (mx >= 38 and mx <= 90 and my >= 55 and my <= 63) then
            Player.dmg += 1
        elseif selected_option == 3 or (mx >= 38 and mx <= 90 and my >= 65 and my <= 73) then
            Player.aspeed += 1
        elseif selected_option == 4 or (mx >= 38 and mx <= 90 and my >= 75 and my <= 83) then
            Player.mspeed += 1
        elseif selected_option == 5 or (mx >= 38 and mx <= 90 and my >= 85 and my <= 93) then
            Player.range += 1
        end
        Player.gold -= 1
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

        pX = flr(entity.posX / 8)
        gridX = pX + moveX

        if (entity.posY % 8 == 0 and
            get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4 and
            get_level(pX + 1, gridY) > 0 and get_level(pX + 1, gridY) < 4) or
            entity.posY % 8 !=  0 or
            (entity.posX % 8 == 0 and entity.posY % 8 == 0 and get_level(pX, gridY) > 0 and get_level(pX, gridY) < 4) then
                entity.posY = entity.posY + moveY
        end

end

----------------Utility------------------------------------
function carve_path(originX, originY, destinationX, destinationY)
    local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
    local non_blocking_tiles = {76, 77, 78, 124, 125, 126}
    while originX ~= destinationX or originY ~= destinationY do
        local dir = rnd(directions)
        local new_x, new_y = originX + dir[1], originY + dir[2]  -- Fix movement
        if is_within_bounds(new_x, new_y) then
            local tile = get_level(new_x, new_y)
            if tile == 0 or tile == 4 then
                mset(new_x, new_y, rnd(non_blocking_tiles))
            end
            originX, originY = new_x, new_y
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

function projectileHit(entity)
    for projectile in all(projectiles) do
        if flr(projectile.posX / 8) == flr(entity.posX / 8) and         //entity.x stimmt れもberein
            flr(projectile.posY / 8) == flr(entity.posY / 8) and not    //entity.y stimmt れもberein
            (getmetatable(entity) == getmetatable(entity.sender)) and not//mobs schieれかen nicht ausversehen auf mobs
            (entity == entity.sender) and not
            (getmetatable(entity) == Projectile) then                              //player kann nicht durch seine eigenen schれもsse verletzt werden
                receivedmg(entity, projectile.dmg)
                projectile.range = flr(projectile.range / 2)
        end
    end
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
    if entity == Portal or entity == Boss then
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

    if xp  == nil or yp == nil then
        return true
     elseif get_level(xp, yp) == 1   then
         return false
    else
        return true
    end
end

----------------Menue------------------


----------------Portal-----------------
Portal = {
posX = 0,
posY = 0,
sprite = 70,

init = function(self)
    local xP = 0
    local yP = 0
        if Player.spawn_area == "tl" then
            xP = flr((64 + rnd(60))) *8
            yP = flr((32 + rnd(28))) *8
        elseif Player.spawn_area == "tr" then
            xP = flr((m_size - 1 - 64 - rnd(60))) *8
            yP = flr((32 + rnd(28))) *8
        elseif Player.spawn_area == "bl" then
            xP = flr((64 + rnd(60))) *8
            yP = flr((((m_size-1)/2) - 32 - rnd(28))) *8
        elseif Player.spawn_area == "tr" then
            xP = flr((m_size - 1 - 64 - rnd(60))) *8
            yP = flr((((m_size-1)/2) - 32 - rnd(28))) *8
        else 
            xP = 8
            yP = flr((32 + rnd(28))) *8
    end
    -- if spawnPointWall(xP, yP) then
    --     self:init()
    -- else
        self.posX = xP
        self.posY = yP
    -- end
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
00eee000000eee0033333333330000000000000333333333008040000004080000000000000000000000000033355533333b3b33b33333b33333333333555533
00eeee0000eeee0033333333333000000000003333333333800004044040000800000000000000000000000033355533b333b3b33333333b3333333355554453
00ccee0000eecc00333333333333000000000333333333330400004ee4000040000000000000000000000000333455333333b333333333333333333355445445
00ccee0000eecc00ccccc3333333300000003333333ccccc040004eeee400040000000000000000000000000333445333b3b333b333333333333333355454445
00eeee0000eeee00ccccc3333333330000033333333ccccc00404ee22ee4040000000000000000000000000033344433b333333333b3b3333333333354544455
00eeee0000eeee00ccccc3333333333000333333333ccccc0004ee2222ee40000000000000000000000000003344443333b33b3b333b33333333333354545555
00eeee0000eeee00ccccc3333333333003333333333ccccc4804e828828e408400000000000000000000000033444433b33333b333333b333333333355445455
00ee00000000ee00333333333333333003333333333333334004e288882e400400000000000000000000000033444433333b333b333333333333333355555555
000ee000000ee000333333333333333003333333333333330404e228822e404000000000000000001100101133aaaa3355555555555555555555555535555553
00eeee0000eeee00333333333333333003333333333333330044e228822e440000005000000000000022ee003aaaaaa355555555555555555555555554454445
00eeee0000ecce00333333333333333003333333333333330004e828828e40000053450000000000122e2e21aaaaaaaa35555553355555533555555354554445
00eeee0000ecce00333333333333333003333333333333338004e282282e4008054553400000000002e22220999aaaaa33555533335555333355553355544445
00eeee0000eeee0033333333333333300333333333333333004555555555540005355400000000001ee2e2e199999aaa33333333333333333333333355444455
00eeee0000eeee00333333330000000000000000033333330499999999999940044343500000000002e22e20999999aa33333333333333333333333354444545
00eeee0000eeee003333333300000000000000000333333345555555555555540034450000000000102e220199999999b33333b333333b333333333355444445
000e0000000e000033333333000000000000000003333333499999999999999400040000000000000101011039999993333b333b333333333333333355555555
00000000000000000000033333300000000003333330000000000000000000000000000000000000000000000000000000000000000000000000000055555555
00000000000000000000333333330000000033333333000000000000000000000000000000000000000000000000000000000000000000000000000055454445
00000000000000000003333333333000000333333333300000000000000000000000000000000000000000000000000000000000000000000000000054444455
00000000000000000033333333333300003333cccc33330000000000000000000000000000000000000000000000000000000000000000000000000054444455
0000000000000000033333333333333003333cccccc3333000000000000000000000000000000000000000000000000000000000000000000000000054554555
0000000000000000033333333333333003333cccccc3333000000000000000000000000000000000000000000000000000000000000000000000000054445445
0000000000000000033333333333333003333cccccc3333000000000000000000000000000000000000000000000000000000000000000000000000055444445
0000000000000000033333333333333003333cccccc3333000000000000000000000000000000000000000000000000000000000000000000000000055555555
00000000000000000333333333333330033333cccc33333000000000000000000000000000000000000000000000000033333393333333333333333355544555
0000000000000000033333333333333003333333333333300000000000000000000000000000000000000000000000003b3b39a9333333b3332b333355445544
00000000000000000333333333333330033333333333333000000000000000000000000000000000000000000000000033b33393383333333223b3b355555545
0000000000000000033333333333333003333333333333300000000000000000000000000000000000000000000000003333333382b333333e33b33355555555
00000000000000000333333333333330033333333333333000000000000000000000000000000000000000000000000033333333383338333333b33344555455
0000000000000000000033330000000000003333000000000000000000000000000000000000000000000000000000003393333333338283333bb33355544455
00000000000000000000333300000000000033330000000000000000000000000000000000000000000000000000000039a933b333333b33b33b333355445554
00000000000000000000333300000000000033330000000000000000000000000000000000000000000000000000000033933333b3333333b333333b55555545
__gff__
0000000000000000000000008080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000001000000000000000001000001000000010000000000000000000000000000000100000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
