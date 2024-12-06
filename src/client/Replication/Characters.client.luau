local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Parent.Zap)

local Entities = require(ReplicatedStorage.Shared.Replication.Entities)

local function createCharacter(userId: number, entity: number)
    local humanoidDescription = game.Players:GetHumanoidDescriptionFromUserId(userId)
    local character = Players:CreateHumanoidModelFromDescription(humanoidDescription, Enum.HumanoidRigType.R15)
    character.Parent = game.Workspace

    local root = character:FindFirstChild("HumanoidRootPart")

    if root then
        Entities.addManually(entity, root)
    end

    local humanoid = character:FindFirstChild("Humanoid")

    if humanoid then
        Workspace.CurrentCamera.CameraSubject = humanoid
    end
end

local existingEntities = Zap.RequestEntities.Call()

if existingEntities then
    for i, entry in existingEntities do
        createCharacter(entry.player.UserId, entry.entity)
    end    
end

Zap.UpdateEntity.SetCallback(function(data)
    if data.added then
        createCharacter(data.player.UserId, data.entity)
    else
        Entities.remove(data.entity)
    end
end)