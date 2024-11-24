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

local function characterAdded(newPlayer: Player, char: Model)
    print("Character added")
    local otherRoot = character:WaitForChild("HumanoidRootPart") :: BasePart

    if playerSnapshots[root] == nil then
        playerSnapshots[otherRoot] = Snapshots.new(2)
    end    
end

for i, v in pairs(Players:GetPlayers()) do
    if v ~= player then
        v.CharacterAdded:Connect(function(char)
            characterAdded(v, char)
        end)    
    end
end

Players.PlayerAdded:Connect(function(newPlayer)
    if newPlayer == player then
        return
    end

    newPlayer.CharacterAdded:Connect(function(char)
        characterAdded(player, char)
    end)

    newPlayer.CharacterRemoving:Connect(function(character: Model)
        local otherRoot = character:WaitForChild("HumanoidRootPart") :: BasePart
        playerSnapshots[otherRoot] = nil
    end)
end)

-- Replicate position to server
RunService.PostSimulation:Connect(function()
    if os.clock() - lastTick >= replicationRate then
        lastTick = os.clock()

        Zap.RequestReplication.Fire({
            cframe = root.CFrame,
        })

        -- Interpolate other characters
        local roots = {}
        local cframes = {}

        for i, v in pairs(playerSnapshots) do
            local currentSnapshot = Snapshots.getLatestFrame(v)

            if currentSnapshot then
                local previousSnapshot = Snapshots.getPreviousFrame(v) or currentSnapshot

                local newCFrame = Interpolation.getCFrame(previousSnapshot, currentSnapshot)

                table.insert(roots, i)
                table.insert(cframes, newCFrame)
            end
        end

        if #roots == #cframes then
            Workspace:BulkMoveTo(roots, cframes)
        end
    end
end)

-- Add all the snapshots to their respective buffers
Zap.BroadcastReplication.SetCallback(function(data)
    for i, v in pairs(data.map) do
        if v.root == root then
            Snapshots.addFrame(snapshotLog, data.frame, v.cframe)
        else
            if playerSnapshots[v.root] then
                Snapshots.addFrame(playerSnapshots[v.root], data.frame, v.cframe)

                print(Snapshots.getLatestFrame(playerSnapshots[v.root]))
            end
        end
    end
end)
