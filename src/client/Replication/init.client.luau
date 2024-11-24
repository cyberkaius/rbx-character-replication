local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character and character:FindFirstChild("HumanoidRootPart")

root.Anchored = false

local replicationRate = 1 / Interpolation.frameRate

local lastTick = os.clock()
local currentFrame = 1

RunService.PostSimulation:Connect(function()
    if os.clock() - lastTick >= replicationRate then
        Zap.RequestReplication.Fire({
            frameNumber = currentFrame,
            cframe = root.CFrame,
        })

        currentFrame += 1

        if currentFrame > Interpolation.frameRate then
            currentFrame = 1
        end
    end
end)

Zap.BroadcastReplication.SetCallback(function(data)
    local cframes = {}
    local roots = {}

    for i, v in pairs(data) do
        if v.root ~= root then
            table.insert(cframes, v.cframe)
            table.insert(roots, v.root)
        end
    end

    if #cframes > 0 and #roots > 0 then
        Workspace:BulkMoveTo(roots, cframes)
    end
end)
