local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character and character:WaitForChild("HumanoidRootPart")

root.Anchored = false

local lastTick = os.clock()

-- Local client buffer
local localClientBuffer = SnapshotBuffer.new(Interpolation.replicationRate / 2)

-- Other clients buffers
local remoteClientBuffers = {} :: {[BasePart]: SnapshotBuffer.Buffer}

-- Replicate locael position to server
RunService.PostSimulation:Connect(function()
    if os.clock() - lastTick >= Interpolation.packetFrequency then
        lastTick = os.clock()

        Zap.RequestReplication.Fire({
            cframe = root.CFrame,
        })
    end
end)

-- Interpolate other characters
RunService.RenderStepped:Connect(function()
    local roots = {}
    local cframes = {}

    for rootPart, buffer in pairs(remoteClientBuffers) do
        local renderTime = os.clock() - Interpolation.bufferDelay
        local snapshotA, snapshotB = SnapshotBuffer.findClosestSnapshot(buffer, renderTime)

        if snapshotA and snapshotB then
            local newCFrame = Interpolation.getCFrame(snapshotA, snapshotB, renderTime)

            table.insert(roots, rootPart)
            table.insert(cframes, newCFrame)        
        end
    end

    if #roots == #cframes then
        Workspace:BulkMoveTo(roots, cframes)
    end
end)

-- Receive packets from server
Zap.BroadcastReplication.SetCallback(function(data)
    for i, v in pairs(data.map) do
        if v.root == root then
            -- Add snapshot to the local player's buffer
            SnapshotBuffer.addSnapshot(localClientBuffer, data.frame, v.cframe)
        else
            -- Add snapshot to the remote client's buffers
            if not remoteClientBuffers[v.root] then
                -- Todo: delete snapshot log when character dies
                remoteClientBuffers[v.root] = SnapshotBuffer.new(Interpolation.replicationRate / 2)
            end

            SnapshotBuffer.addSnapshot(remoteClientBuffers[v.root], data.frame, v.cframe)
        end
    end
end)
