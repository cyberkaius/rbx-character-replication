local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Parent.Zap)

local Player = require(script.Parent.Parent.Player)

local Entities = require(ReplicatedStorage.Shared.Replication.Entities)

local function addEntity(data: {entity: number, player: Player})
    local player = Player.getPlayer(data.player.UserId) :: Player.MyPlayer
    Player.loadCharacter(player):Await()

    if player.root then
        if Entities.getInstance(data.entity) == nil then
            Entities.addManually(data.entity, player.root)
        end
    end

    if player.humanoid then
        Workspace.CurrentCamera.CameraSubject = player.humanoid
    end
end

local existingEntities = Zap.RequestEntities.Call()

if existingEntities then
    for i, data in existingEntities do
        addEntity(data)
    end    
end

Zap.UpdateEntity.SetCallback(function(data)
    if data.added then
        addEntity(data)
    else
        Entities.remove(data.entity)
    end
end)