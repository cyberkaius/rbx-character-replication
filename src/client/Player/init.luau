local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Future = require(ReplicatedStorage.Packages.Future)

local Entities = require(ReplicatedStorage.Shared.Replication.Entities)

export type MyPlayer = {
    LocalPlayer: Player,
    Character: Model,
    Humanoid: Humanoid & {
        HumanoidDescription: HumanoidDescription,
        Animator: Animator,
        AutoRotate: boolean
    },
    Root: BasePart,
}

local player = {} :: MyPlayer
player.LocalPlayer = Players.LocalPlayer

Entities.connect(function(entity, added)
    local root = Entities.getInstance(entity) :: BasePart?

    if root then
        local player = Players:GetPlayerFromCharacter(root.Parent)

        if player == Players.LocalPlayer then
            player.Character = root.Parent
            player.Root = root
        end
    end
end)

return Future.new(function()
    repeat task.wait() until player.Character and player.Root
    
    return player
end)