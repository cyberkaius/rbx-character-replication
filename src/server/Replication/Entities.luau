local Entities = {}

local list = {} :: {Instance?}

function Entities.add(root: Instance): number
    for i = 1, #list do 
        if list[i] == nil then
            list[i] = root

            return i
        end
    end

    table.insert(list, root)

    -- TODO: block entity list from going past a u8 value (highly unlike to happen anyway)

    return #list
end

function Entities.getList()
    return list
end

function Entities.getInstance(key: number): Instance?
    if key >= 1 and key <= #list then
        if list[key] then
            return list[key]
        end
    end

    return
end

function Entities.getKey(instance: Instance): number?
    for i, v in pairs(list) do
        if v == instance then
            return i
        end
    end

    return
end

function Entities.remove(key: number)
    if key >= 1 and key <= #list then
        if list[key] then
            list[key] = nil
        end
    end
end

return Entities