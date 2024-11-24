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

-- Create a snapshot buffer of 2 for every player
local playerSnapshots = {} :: {[BasePart]: Snapshots.Snapshots}

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        local otherRoot = character:WaitForChild("HumanoidRootPart") :: BasePart

		if (not otherRoot == root) and (not playerSnapshots[root]) then
            playerSnapshots[otherRoot] = Snapshots.new(2)
		end
    end)

    player.CharacterRemoving:Connect(function(character: Model)
        local otherRoot = character:WaitForChild("HumanoidRootPart") :: BasePart

        if not otherRoot == root then
            playerSnapshots[otherRoot] = nil
        end
    end)
end)

-- Replicate position to server
RunService.PostSimulation:Connect(function()
    if os.clock() - lastTick >= replicationRate then
        lastTick = os.clock()

        Zap.RequestReplication.Fire({
            cframe = root.CFrame,
        })
    end
end)

-- Add frames of every player and interpolate their positions
Zap.BroadcastReplication.SetCallback(function(data)
    local cframes = {}
    local roots = {}

    for i, v in pairs(data.roots) do
        if v ~= root then
            Snapshots.addFrame(playerSnapshots[v], data.frame, data.cframes[i])

            local currentSnapshot = Snapshots.getLatestFrame(playerSnapshots[v])
            local previousSnapshot = Snapshots.getPreviousFrame(playerSnapshots[v])

            local cframeToAdd = data.cframes[i]

            if currentSnapshot and previousSnapshot then
                cframeToAdd = Interpolation.getCFrame(previousSnapshot, currentSnapshot)
            end

            table.insert(roots, v)
            table.insert(cframes, cframeToAdd)
        else
            Snapshots.addFrame(snapshotLog, data.frame, data.cframes[i])
        end
    end

    if #data.cframes == #data.roots then
        Workspace:BulkMoveTo(cframes, roots)
    end
end)
