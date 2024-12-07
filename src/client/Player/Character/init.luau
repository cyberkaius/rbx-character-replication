local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)

export type Character = {
    model: Model,
    root: BasePart,
    humanoid: Humanoid,
    entityId: number,
    canMove: boolean,
    moveVector: Vector3,
    snapshotBuffer: SnapshotBuffer.Buffer
}

local Character = {}
Character._characters = {} :: {Character}

function Character.getList(): {Character}
    return Character._characters
end

function Character.new(player: Player, entityId: number, cframe: CFrame): Character
    local character = {} :: Character

    local userId = player.UserId
    if userId <= 0 then userId = 1 end

    local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(userId)

    local model = Players:CreateHumanoidModelFromDescription(humanoidDescription, Enum.HumanoidRigType.R15)
    model.Parent = game.Workspace

    character.model = model
    character.root = model:WaitForChild("HumanoidRootPart")   
    character.humanoid = model:WaitForChild("Humanoid") 
    character.entityId = entityId
    character.snapshotBuffer = SnapshotBuffer.new(Interpolation.replicationRate / 2)
    character.canMove = true
    character.moveVector = Vector3.zero
    character.root.CFrame = cframe

    Character._characters[entityId] = character

    return character
end

function Character.destroy(character: Character)
    if character.model then
        character.model:Destroy()
    end
end

return Character
