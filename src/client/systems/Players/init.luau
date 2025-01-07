local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Planck = require(ReplicatedStorage.packages.planck)
local World = require(ReplicatedStorage.shared.ecs.world)
local Cts = require(script.Parent.Parent.components)

local localPlayer = World:entity()
World:set(localPlayer, Cts.Instance, Players.LocalPlayer)
World:set(localPlayer, Cts.Player)
World:set(localPlayer, Cts.LocalPlayer)

Players.PlayerAdded:Connect(function(player: Player)
    local newPlayer = World:entity()
    World:set(newPlayer, Cts.Instance, player)
    World:set(newPlayer, Cts.Player)
end)

function system()
    for entity, player, instance in World:query(Cts.Player, Cts.Instance) do
        print("Found " .. entity)
    end

    for entity, localPlayer in World:query(Cts.LocalPlayer) do
        print("Found " .. entity)
    end
end

return {
    phase = Planck.Phase.Update,
    system = system,
}