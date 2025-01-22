dsa = {
    m_size = 129
    roughness = flr(rnd(3)) -1
    function adjust_roughness(size)
        adj = 2
        chance = rnd()
        if chance > 0.9 then
            adj = rnd(()adj*2)+1)-adj
        end
        if chance >= 0.75 then adj+=1 end
        return adj
    end
    function init_grid()
        grid = {}
        for x = 1, m_size do
            local row = ""
            for y = 1, m_size do
                row = row .. "0" -- Append "0" for each column in the row
            end
            grid[x] = row -- Assign the constructed row to the grid
        end
        -- Set the corners
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
                local val = avg + adj_roughness(size)
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
                local val = avg + adj_roughness(size)
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
}
--usage init_grid cartridge:
--dsa.init_grid()
--dsa.create_map()
--dsa.set_map()