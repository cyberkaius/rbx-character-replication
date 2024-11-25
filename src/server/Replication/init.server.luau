local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)

local playerSnapshots = {} :: {[BasePart]: SnapshotBuffer.Buffer}

local bufferSize = Interpolation.replicationRate / 2

-- Create snapshot of roots when character added / removed
Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart

		-- Disable default replication by anchoring
		task.wait()
		root.Anchored = true

        if not playerSnapshots[root] then
            playerSnapshots[root] = SnapshotBuffer.newBySize(bufferSize)
        end    
    end)

    player.CharacterRemoving:Connect(function(character: Model)
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart
        playerSnapshots[root] = nil
    end)
end)

-- Replicate current snapshots to all clients

local lastTick = os.clock()

local currentFrame = 1

RunService.Heartbeat:Connect(function()
	if os.clock() - lastTick >= Interpolation.packetFrequency then
		local roots = {}
		local cframes = {}

		local map = {} :: {root: BasePart, cframe: CFrame}

		for root, log in pairs(playerSnapshots) do
			local lastSnapshot = SnapshotBuffer.getLatestSnapshot(log)

			if lastSnapshot then
				table.insert(map, {
					root = root,
					cframe = lastSnapshot.cframe
				})

				table.insert(roots, root)
				table.insert(cframes, lastSnapshot.cframe)
			end
		end

		-- In future don't send the whole CFrame as it's really slow
		if #map > 0 then
			Zap.BroadcastReplication.FireAll({
				frame = currentFrame,
				map = map
			})	
		end
		
		-- Interpolate players on server positions
		if (#cframes == #roots) and (#cframes > 0) and (#roots > 0) then
			-- Broadcast replication to all clients
			

			-- Move characters on serve
			--Workspace:BulkMoveTo(roots, cframes)
		end

		currentFrame += 1

		if currentFrame > Interpolation.replicationRate then
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
		SnapshotBuffer.addSnapshot(log, currentFrame, data.cframe)
	end
end)