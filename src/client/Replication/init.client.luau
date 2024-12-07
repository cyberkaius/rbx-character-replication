local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = require(script.Parent.Player)
local Character = require(script.Parent.Player.Character)
local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)
local Tick = require(ReplicatedStorage.Shared.Replication.Tick)
local Transform = require(ReplicatedStorage.Shared.Replication.Transform)

local localPlayer = Player.getLocalPlayer(true)
local localCharacter = localPlayer.character
local localRoot = localCharacter.root

local currentTime = Tick.toTimestamp(Zap.RequestServerTick.Call())
local lastTick = os.clock()

local queuedTransform: Transform.Transform = {
    x = localRoot.CFrame.X,
    y = localRoot.CFrame.Y,
    z = localRoot.CFrame.Z,
    yRotation = math.rad(localRoot.Orientation.Y)
}

-- Replicate local position to server
RunService.PostSimulation:Connect(function()
    if os.clock() - lastTick >= Interpolation.packetFrequency then
        lastTick = os.clock()

        queuedTransform = {
            x = localRoot.CFrame.X,
            y = localRoot.CFrame.Y,
            z = localRoot.CFrame.Z,
            yRotation = math.rad(localRoot.Orientation.Y)
        }

        Zap.RequestReplication.Fire(queuedTransform)
    end
end)

-- Interpolate other characters
RunService.RenderStepped:Connect(function(deltaTime: number)
    currentTime += deltaTime

    local roots = {}
    local cframes = {}

    local renderAt = currentTime - Interpolation.bufferDelay - (Interpolation.packetFrequency)

    for i, player in Player.getPlayers() do
        if player == localPlayer then
            continue
        end

        if player.character and player.character.root then
            local snapshotA, snapshotB = SnapshotBuffer.findClosestSnapshot(player.character.snapshotBuffer, renderAt)

            if snapshotA and snapshotB then
                local newCFrame = Interpolation.getCFrame(snapshotA, snapshotB, renderAt)
    
                table.insert(roots, player.character.root)
                table.insert(cframes, newCFrame)        
            end
        end
    end

    if #roots == #cframes then
        Workspace:BulkMoveTo(roots, cframes)
    end
end)

-- Receive packets from server
Zap.BroadcastReplication.SetCallback(function(data)
    if Tick.raw > data.tick then
        Tick.wrapCount += 1
    end

    Tick.raw = data.tick

    local timestamp = Tick.toTimestamp(data.tick)

    currentTime = timestamp

    if queuedTransform and localCharacter then
        SnapshotBuffer.addSnapshot(localCharacter.snapshotBuffer, {
            timestamp = timestamp,
            transform = queuedTransform
        })    
    end

    local characters = Character.getList()

    local localEntityId = localCharacter and localCharacter.entityId

    for i, data in data.map do
        if data.entity == localEntityId then
            continue
        end

        local character = characters[data.entity]

        if character then
            local transform = {
                x = data.x, 
                y = data.y, 
                z = data.z,
                yRotation = data.yRotation
            }

            SnapshotBuffer.addSnapshot(character.snapshotBuffer, {
                timestamp = timestamp,
                transform = transform
            })
        end
    end
end)
