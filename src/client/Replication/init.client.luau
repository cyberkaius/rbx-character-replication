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
local localClientBuffer = SnapshotBuffer.new(Interpolation.replicationRate)

local lastTick = os.clock()
local lastServerTick = 0

local queuedTransform = {
    x = root.CFrame.X,
    y = root.CFrame.Y,
    z = root.CFrame.Z,
    yRotation = math.rad(root.Orientation.Y)
} 

-- Other clients buffers
local remoteClientBuffers = {} :: {SnapshotBuffer.Buffer}

-- Get entity updates
local remoteClientRoots = {} :: {Instance?}

Zap.RequestEntities.Fire()

Zap.ReturnEntities.SetCallback(function(data)
    -- Updating entities
    for i, entry in data do
        local remoteRoot = entry.player.Character and entry.player.Character:FindFirstChild("HumanoidRootPart")
        remoteClientRoots[entry.entity] = remoteRoot
        remoteClientBuffers[entry.entity] = SnapshotBuffer.new(Interpolation.replicationRate / 2)
    end
end)

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
            x = root.CFrame.X,
            y = root.CFrame.Y,
            z = root.CFrame.Z,
            yRotation = math.rad(root.Orientation.Y)
        }

        Zap.RequestReplication.Fire(queuedTransform)
    end
end)

-- Interpolate other characters
RunService.RenderStepped:Connect(function(deltaTime: number)
    if next(remoteClientBuffers) == nil then
        return
    end

    local roots = {}
    local cframes = {}

    local currentTimestamp =  Tick.toTimestamp(Tick.raw)

    local renderAt = currentTimestamp - Interpolation.bufferDelay

    for key, buffer in pairs(remoteClientBuffers) do
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
        Tick.wrapCount += 1
    end

    Tick.raw = data.tick

    lastServerTick = os.clock()

    local timestamp = Tick.toTimestamp(data.tick)

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
