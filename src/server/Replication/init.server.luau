local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)
local EntityList = require(script.EntityList)

local playerSnapshots = {} :: {SnapshotBuffer.Buffer}

local bufferSize = Interpolation.replicationRate / 2

-- Create snapshot of roots when character added / removed
Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
		local key = EntityList.add(player)

		Zap.UpdateEntity.FireExcept(player, {
			entity = key,
			player = player,
			add = true
		})

        playerSnapshots[key] = SnapshotBuffer.new(bufferSize)

		-- Disable default replication by anchoring
		task.wait()
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart
		root.Anchored = true
    end)

    player.CharacterRemoving:Connect(function(character: Model)
		local key = EntityList.getKey(player)

		if key then
			playerSnapshots[key] = nil
			EntityList.remove(key)	

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
		local roots = {}
		local cframes = {}

		local map = {} :: {root: BasePart, cframe: CFrame}

		for key, log in pairs(playerSnapshots) do
			local lastSnapshot = SnapshotBuffer.getLatestSnapshot(log)

			if lastSnapshot then
				table.insert(map, {
					entity = key,
					x = lastSnapshot.data.x,
					y = lastSnapshot.data.y,
					z =  lastSnapshot.data.z,
				})

				table.insert(roots, key)
				table.insert(cframes, lastSnapshot.data)
			end
		end

		-- In future don't send the whole CFrame as it's really slow
		-- Also todo: dont send the receiving player's data back
		if #map > 0 then
			Zap.BroadcastReplication.FireAll({
				frame = currentFrame,
				map = map
			})	
		end
		
		-- Interpolate players on server positions
		if (#cframes == #roots) and (#cframes > 0) and (#roots > 0) then
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
	local entityId = EntityList.getKey(player)

	if entityId then
		SnapshotBuffer.addSnapshot(playerSnapshots[entityId], currentFrame, data)
	end
end)