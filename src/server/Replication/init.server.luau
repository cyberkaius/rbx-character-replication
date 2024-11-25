local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)
local Entities = require(script.Entities)

local playerSnapshots = {} :: {SnapshotBuffer.Buffer}

-- Create snapshot of roots when character added / removed
Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
		local key = Entities.add(player)

		Zap.UpdateEntity.FireExcept(player, {
			entity = key,
			player = player,
			add = true
		})

        playerSnapshots[key] = SnapshotBuffer.new(Interpolation.replicationRate / 2)

		-- Disable default replication by anchoring
		task.wait()
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart
		root.Anchored = true
    end)

    player.CharacterRemoving:Connect(function(character: Model)
		local key = Entities.getKey(player)

		if key then
			playerSnapshots[key] = nil
			Entities.remove(key)	

			Zap.UpdateEntity.FireExcept(player, {
				entity = key,
				player = player,
				add = false
			})
		end	
    end)
end)

-- Replicate current snapshots to all clients

local lastTick = os.clock()

local currentFrame = 1

RunService.Heartbeat:Connect(function()
	if os.clock() - lastTick >= Interpolation.packetFrequency then
		-- local roots = {}
		-- local cframes = {}

		-- for key, log in pairs(playerSnapshots) do
		-- 	local lastSnapshot = SnapshotBuffer.getLatestSnapshot(log)

		-- 	if lastSnapshot then
		-- 		table.insert(roots, key)
		-- 		table.insert(cframes, lastSnapshot.data)
		-- 	end
		-- end
		
		-- -- Interpolate players on server positions
		-- if (#cframes == #roots) and (#cframes > 0) and (#roots > 0) then
		-- 	--Workspace:BulkMoveTo(roots, cframes)
		-- end

		currentFrame += 1

		if currentFrame > Interpolation.replicationRate then
			currentFrame = 0
		end
    end
end)

-- Add snapshot frame
Zap.RequestReplication.SetCallback(function(player, data)
	-- Add new player data to snapshot
	local entityId = Entities.getKey(player)

	if entityId then
		SnapshotBuffer.addSnapshot(playerSnapshots[entityId], currentFrame, data)
	end

	-- Send them back other player's data
	local map = {} :: {root: BasePart, cframe: CFrame}

	for key, snapshot in pairs(playerSnapshots) do
		if key ~= entityId then
			local lastSnapshot = SnapshotBuffer.getLatestSnapshot(snapshot)

			if lastSnapshot then
				table.insert(map, {
					entity = key,
					x = lastSnapshot.transform.x,
					y = lastSnapshot.transform.y,
					z = lastSnapshot.transform.z,
				})
			end	
		end
	end

	if #map > 0 then
		Zap.BroadcastReplication.Fire(player, {
			frame = currentFrame,
			map = map
		})	
	end
end)