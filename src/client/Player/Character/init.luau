local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Future = require(ReplicatedStorage.Packages.Future)

local Zap = require(script.Parent.Parent.Zap)

export type Character = {
    model: Model,
    root: BasePart,
    humanoid: Humanoid,
    entityId: number
}

local Character = {}

function Character.new(player: Player): Character?
    local character = {} :: Character

    local userId = player.UserId
    if userId <= 0 then userId = 1 end

    local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(userId)

    local character = Players:CreateHumanoidModelFromDescription(humanoidDescription, Enum.HumanoidRigType.R15)
    character.Parent = game.Workspace

    local root = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    character.model = character
    character.root = root   
    character.humanoid = humanoid 
    character.entityId = Zap.RequestEntityId.Call(player)

    if character.entityId then
        return character
    end

    return
end

function Character.destroy(character: Character)
    if character.model then
        character.model:Destroy()
    end
end

return Character
