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

		local cframes: {CFrame} = {}
		local roots: {Instance} = {}

		for key, snapshot in pairs(playerSnapshots) do
			local lastSnapshot = SnapshotBuffer.getLatestSnapshot(snapshot)

			if lastSnapshot then
				table.insert(map, {
					entity = key,
					x = lastSnapshot.transform.x,
					y = lastSnapshot.transform.y,
					z = lastSnapshot.transform.z,
					yRotation = lastSnapshot.transform.yRotation
				})

				local entity = Entities.getInstance(key) :: Player
				local root = entity.Character and entity.Character:FindFirstChild("HumanoidRootPart")

				if root then
					table.insert(cframes, CFrame.new(lastSnapshot.transform.x, lastSnapshot.transform.y, lastSnapshot.transform.z) * CFrame.Angles(0, lastSnapshot.transform.yRotation, 0))
					table.insert(roots, root)	
				end
			end	
		end

		if (#cframes == #roots) and (#cframes > 0) and (#roots > 0) then
			Workspace:BulkMoveTo(roots, cframes)
		end
		
		if #map > 0 then
			Zap.BroadcastReplication.FireAll({
				tick = Tick.raw,
				map = map
			})		
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

-- Add snapshots for each entity
Entities.connect(function(key, added)
	if added then
		playerSnapshots[key] = SnapshotBuffer.new(Interpolation.replicationRate / 2)
	else
		playerSnapshots[key] = nil
	end
end)