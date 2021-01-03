local function getAllData(t, prevData)
    -- if prevData == nil, start empty, otherwise start with prevData
    local data = prevData or {}

    -- copy all the attributes from t
    for k,v in pairs(t) do
        data[k] = data[k] or v
    end

    -- get t's metatable, or exit if not existing
    local mt = getmetatable(t)
    if type(mt)~='table' then return data end

    -- get the __index from mt, or exit if not table
    local index = mt.__index
    if type(index)~='table' then return data end

    -- include the data from index into data, recursively, and return
    return getAllData(index, data)
end

local function table_print (tt, indent, done)
    done = done or {}
    indent = indent or 0
    if type(tt) == "table" then
        local sb = {}
        for key, value in pairs (tt) do
            table.insert(sb, string.rep (" ", indent)) -- indent it
            if type (value) == "table" and not done [value] then
                done [value] = true
                table.insert(sb, key .. " = {\n");
                table.insert(sb, table_print (value, indent + 2, done))
                table.insert(sb, string.rep (" ", indent)) -- indent it
                table.insert(sb, "}\n");
            elseif "number" == type(key) then
                table.insert(sb, string.format("\"%s\"\n", tostring(value)))
            else
                table.insert(sb, string.format(
                        "%s = \"%s\"\n", tostring (key), tostring(value)))
            end
            -- get t's metatable, or exit if not existing
            local mt = getmetatable(tt)
            if type(mt)=='table' then
                local index = mt.__index
                if type(index)=='table' then
                    table.insert(sb, table_print (index, indent + 2, done))
                end
            end
        end
        return table.concat(sb)
    else
        return tt .. "\n"
    end
end

local function to_string( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return table_print(tbl)
    elseif  "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
end

local function recursiveGetChildren(frame, indent)
    indent = indent or 1
    getAttributes(frame)
    if frame:GetNumChildren() > 0 then
        local kids = {frame:GetChildren()}
        for _, child in ipairs(kids) do
            print(to_string(child))
            --local childName = child:GetName() or " "
            --print(string.rep(" ", indent) .. childName)
            recursiveGetChildren(child, indent + 1)
        end
    end
end