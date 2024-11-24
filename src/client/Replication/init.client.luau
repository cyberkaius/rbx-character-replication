local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local Snapshots = require(ReplicatedStorage.Shared.Replication.Snapshots)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character and character:FindFirstChild("HumanoidRootPart")

root.Anchored = false

local snapshotLog = Snapshots.new(Interpolation.frameRate / 2)

local replicationRate = 1 / Interpolation.frameRate

local lastTick = os.clock()

-- Replicate position to server
RunService.PostSimulation:Connect(function()
    if os.clock() - lastTick >= replicationRate then
        lastTick = os.clock()

        Zap.RequestReplication.Fire({
            cframe = root.CFrame,
        })
    end
end)

-- Update other players positions locally
Zap.BroadcastReplication.SetCallback(function(data)
    local cframes = {}
    local roots = {}

    local myCFrame = nil :: CFrame?

    for i, v in pairs(data.roots) do
        if v ~= root then
            myCFrame = data.cframes[i]
        end
    end

    if #data.cframes == #data.roots then
        Workspace:BulkMoveTo({}, {})
    end

    -- Add new snapshot to local snapshot list
    if myCFrame then
        Snapshots.addFrame(snapshotLog, data.frame, myCFrame)
    end
end)
