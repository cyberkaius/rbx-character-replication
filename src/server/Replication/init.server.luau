local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local Snapshots = require(ReplicatedStorage.Shared.Replication.Snapshots)

local playerSnapshots = {} :: {[BasePart]: Snapshots.Snapshots}

local bufferSize = Interpolation.frameRate / 2

-- Create snapshot of roots when character added / removed
Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart

		-- Disable default replication by anchoring
		task.wait()
		root.Anchored = true

        if not playerSnapshots[root] then
            playerSnapshots[root] = Snapshots.new(bufferSize)
        end    
    end)

    player.CharacterRemoving:Connect(function(character: Model)
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart
        playerSnapshots[root] = nil
    end)
end)

-- Replicate current snapshots to all clients

local replicationRate = 1 / Interpolation.frameRate
local lastTick = os.clock()

local currentFrame = 1

RunService.Heartbeat:Connect(function()
	if os.clock() - lastTick >= replicationRate then
		local roots = {}
		local cframes = {}

		for root, log in pairs(playerSnapshots) do
			local lastSnapshot = Snapshots.getLatestFrame(log)

			-- In future don't send the whole CFrame as it's really slow
			if lastSnapshot then
				table.insert(roots, root)
				table.insert(cframes, lastSnapshot.cframe)
			end
		end

		if (#cframes == #roots) and (#cframes > 0) and (#roots > 0) then
			-- Broadcast replication to all clients
			Zap.BroadcastReplication.FireAll({
				frame = currentFrame,
				roots = roots,
				cframes = cframes
			})

			-- Move characters on serve
			--Workspace:BulkMoveTo(roots, cframes)
		end

		currentFrame += 1

		if currentFrame > Interpolation.frameRate then
			currentFrame = 0
		end
    end
end)

-- Add snapshot frame
Zap.RequestReplication.SetCallback(function(player, data)
	local character = player.Character :: any
	local root = character and character.HumanoidRootPart :: BasePart

	local log = playerSnapshots[root]

	if log then
		Snapshots.addFrame(log, currentFrame, data.cframe)
	end
end)