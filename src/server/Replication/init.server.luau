local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)
local Entities = require(script.Entities)
local Tick = require(ReplicatedStorage.Shared.Replication.Tick)

local playerSnapshots = {} :: {SnapshotBuffer.Buffer}

local lastTick = os.clock()

-- Replicate current snapshots to all clients
RunService.Heartbeat:Connect(function()
	if os.clock() - lastTick >= Interpolation.packetFrequency then
		local map = {} :: {
			entity: number,
			x: number,
			y: number,
			z: number,
		}

		for key, snapshot in pairs(playerSnapshots) do
			local lastSnapshot = SnapshotBuffer.getLatestSnapshot(snapshot)

			if lastSnapshot then
				map[key] = {
					entity = key,
					x = lastSnapshot.transform.x,
					y = lastSnapshot.transform.y,
					z = lastSnapshot.transform.z,
					yRotation = lastSnapshot.transform.yRotation
				}
			end	
		end

		for key, v in Entities.getList() do
			local player = Entities.getInstance(key) :: Player

			if player then
				local newMap = table.clone(map)
				table.remove(newMap, key)

				if #newMap > 0 then
					Zap.BroadcastReplication.Fire(player, {
						tick = Tick.raw,
						map = newMap
					})	
				end
			end
		end

		Tick.increment()
    end
end)

-- Add snapshot frame to buffers when received
Zap.RequestReplication.SetCallback(function(player, data)
	local entityId = Entities.getKey(player)

	if entityId then
		SnapshotBuffer.addSnapshot(playerSnapshots[entityId], {
			timestamp = Tick.toTimestamp(Tick.raw),
			transform = data,
		})
	end
end)

-- Give player the server tick
Zap.RequestServerTick.SetCallback(function(player)
	return Tick.raw
end)

-- TODO: Create humanoid roots for each player in Camera to stop replication
-- Create snapshot of roots when character added / removed
Zap.RequestEntities.SetCallback(function(player: Player)
	local entityMap = {}

	for key, plr in Entities.getList() do
		if plr == player then
			continue
		end

		table.insert(entityMap, {
			entity = key,
			player = plr :: Player 
		})
	end
	
	if #entityMap > 0 then
		return entityMap
	end	

	return nil
end)

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