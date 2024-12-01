local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)
local Tick = require(ReplicatedStorage.Shared.Replication.Tick)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

root.Anchored = false

-- Local client buffer
local localClientBuffer = SnapshotBuffer.new(Interpolation.replicationRate / 2)

local lastTick = os.clock()

local queuedTransform = {
    x = root.Position.X,
    y = root.Position.Y,
    z = root.Position.Z,
    yRotation = root.Rotation.Y
} 

-- Other clients buffers
local remoteClientBuffers = {} :: {SnapshotBuffer.Buffer}

-- Get entity updates
local remoteClientRoots = {} :: {Instance?}

Zap.UpdateEntity.SetCallback(function(data)
    if data.add then
        local remoteRoot = data.player.Character and data.player.Character:FindFirstChild("HumanoidRootPart")
        remoteClientRoots[data.entity] = remoteRoot
        remoteClientBuffers[data.entity] = SnapshotBuffer.new(Interpolation.replicationRate / 2)
    else
        remoteClientRoots[data.entity] = nil
        remoteClientBuffers[data.entity] = nil
    end
end)

-- Replicate local position to server
RunService.PostSimulation:Connect(function()
    if os.clock() - lastTick >= Interpolation.packetFrequency then
        lastTick = os.clock()

        queuedTransform = {
            x = root.Position.X,
            y = root.Position.Y,
            z = root.Position.Z,
            yRotation = root.Rotation.Y
        }

        Zap.RequestReplication.Fire(queuedTransform)
    end
end)

-- Interpolate other characters
RunService.RenderStepped:Connect(function()
    local roots = {}
    local cframes = {}

    for key, buffer in pairs(remoteClientBuffers) do
        local renderAt = os.clock() - Interpolation.bufferDelay - Interpolation.packetFrequency
        local snapshotA, snapshotB = SnapshotBuffer.findClosestSnapshot(buffer, renderAt)

        if snapshotA and snapshotB then
            local newCFrame = Interpolation.getCFrame(snapshotA, snapshotB, renderAt)

            table.insert(roots, remoteClientRoots[key])
            table.insert(cframes, newCFrame)        
        end
    end

    if #roots == #cframes then
        Workspace:BulkMoveTo(roots, cframes)
    end
end)

-- Receive packets from server
Zap.BroadcastReplication.SetCallback(function(data)
    if Tick.raw > data.tick then
        Tick.wrapCounter += 1
    end

    Tick.raw = data.tick

    local timestamp = Tick.toTimestamp(data.tick)

    print(timestamp)

    SnapshotBuffer.addSnapshot(localClientBuffer, {
        timestamp = timestamp,
        transform = queuedTransform
    })

    for i, v in pairs(data.map) do
        local transform = {
            x = v.x, 
            y = v.y, 
            z = v.z,
            yRotation = v.yRotation
        }

        if remoteClientRoots[v.entity] and remoteClientBuffers[v.entity]then
            SnapshotBuffer.addSnapshot(remoteClientBuffers[v.entity], {
                timestamp = timestamp,
                transform = transform
            })
        end
    end
end)
