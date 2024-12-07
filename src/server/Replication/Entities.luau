type Connection = (key: number, added: boolean) -> nil

local Entities = {}

local list: {Instance?} = {}

local listeners: {Connection} = {}
local nextSignalId = 1

function Entities.connect(callback: Connection)
    listeners[nextSignalId] = callback
    nextSignalId += 1

    return nextSignalId
end

function Entities.disconnect(signal: number)
    table.remove(listeners, signal)
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

-- Used by the server
function Entities.add(instance: Instance): number
    for i = 1, #list do 
        if list[i] == nil then
            list[i] = instance

            return i
        end
    end

    table.insert(list, instance)

    -- Call any listeners and tell them an entity was added
    for i, v in listeners do
        v(#list, true)
    end

    -- TODO: block entity list from going past a u8 value (highly unlike to happen anyway)
    return #list
end

-- Used by the client
function Entities.addManually(key: number, instance: Instance)
    list[key] = instance

    for i, v in listeners do
        v(#list, true)
    end
end

function Entities.remove(key: number)
    if key >= 1 and key <= #list then
        if list[key] then
            list[key] = nil

            -- Call any listeners and tell them an entity was removed
            for i, v in listeners do
                v(key, false)
            end
        end
    end
end

return Entities