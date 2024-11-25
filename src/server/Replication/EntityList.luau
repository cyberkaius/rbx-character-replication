-- TODO: 
-- When a new character is added, map their root part to an entity number
-- Send this new number and root over to the client so they can store it
-- When character leaves, remove the entity number from the list and tell the client
-- This way only a number has to be sent over to specify what root to update instead of a whole instance.

local EntityList = {}

local list = {} :: {Instance?}

function EntityList.add(root: Instance): number
    for i = 1, #list do 
        if list[i] == nil then
            list[i] = root

            return i
        end
    end

    table.insert(list, root)

    return #list
end

function EntityList.getInstance(key: number): Instance?
    if key >= 1 and key <= #list then
        if list[key] then
            return list[key]
        end
    end

    return
end

function EntityList.getKey(instance: Instance): number?
    for i, v in pairs(list) do
        if v == instance then
            return i
        end
    end

    return
end

function EntityList.remove(key: number)
    if key >= 1 and key <= #list then
        if list[key] then
            list[key] = nil
        end
    end
end

return EntityList