local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

root.Anchored = false

local lastTick = os.clock()

-- Local client buffer
local localClientBuffer = SnapshotBuffer.new(Interpolation.replicationRate / 2)

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

        Zap.RequestReplication.Fire({
            x = root.Position.X,
            y = root.Position.Y,
            z = root.Position.Z,
        })
    end
end)

-- Interpolate other characters
RunService.RenderStepped:Connect(function()
    local roots = {}
    local cframes = {}

    for key, buffer in pairs(remoteClientBuffers) do
        local latest = SnapshotBuffer.getLatestSnapshot(buffer)

        if latest then
            local newCFrame = CFrame.new(latest.data.x, latest.data.y, latest.data.z)
            table.insert(roots, remoteClientRoots[key])
            table.insert(cframes, newCFrame)  
        end
        

        -- local renderTime = os.clock() - Interpolation.bufferDelay
        -- local snapshotA, snapshotB = SnapshotBuffer.findClosestSnapshot(buffer, renderTime)

        -- if snapshotA and snapshotB then
        --     local newCFrame = Interpolation.getCFrame(snapshotA, snapshotB, renderTime)

        --     table.insert(roots, rootPart)
        --     table.insert(cframes, newCFrame)        
        -- end
    end

    if #roots == #cframes then
        Workspace:BulkMoveTo(roots, cframes)
    end
end)

-- Receive packets from server
Zap.BroadcastReplication.SetCallback(function(data)
    for i, v in pairs(data.map) do
        local posData = {
            x = v.x, 
            y = v.y, 
            z = v.z
        }

        if remoteClientRoots[v.entity] == nil then
            -- Add snapshot to the local player's buffer
            -- TODO: dont send back the player's data, but instead queue the data to be added to the snapshot locally, 
            --then add the frame from the sent back remote client data
            SnapshotBuffer.addSnapshot(localClientBuffer, data.frame, posData)
        else
            if remoteClientBuffers[v.entity] then
                SnapshotBuffer.addSnapshot(remoteClientBuffers[v.entity], data.frame, posData)
            end 
        end
    end
end)
