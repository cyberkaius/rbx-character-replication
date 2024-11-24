local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Zap = require(script.Parent.Zap)

local Snapshots = require(script.Snapshots)

local array = {} :: {roots}

type roots = {
	[BasePart]: {
		x: number,
		y: number,
		z: number,
		rotation: number
	}
}

-- Disable default replication
Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		local root = character:WaitForChild("HumanoidRootPart") :: BasePart
		task.wait()
        root.Anchored = true
	end)
end)

Zap.RequestReplication.SetCallback(function(player, data)
	local character = player.Character :: any
	local root = character and character.HumanoidRootPart :: BasePart

	if not Snapshots[root] then return end

	-- Move player
	--local position = Vector3.new(data.x, data.y, data.z)
	--local rotation = CFrame.Angles(0, data.rotation, 0)

	--root.Position = position

	--root.Rotation = Vector3.new(0, data.rotation, 0)
	--character:PivotTo(CFrame.new(position) * rotation)

	-- Only keep previous 40 snapshots
	local snapshot = data :: Snapshots.Snapshot
	snapshot.tick = os.clock()

	table.insert(Snapshots[root], snapshot)

	if #Snapshots[root] > 40 then
		table.remove(Snapshots[root], 1)
	end
end)

local replicationRate = 1/40
local lastTick = os.clock()

RunService.Heartbeat:Connect(function()
	if os.clock() - lastTick >= replicationRate then
		local map = {}

		for root, list in pairs(Snapshots) do
			local lastSnapshot = list[#list]

			if lastSnapshot ~= nil then
				table.insert(map, {
					root = root,
					cframe = lastSnapshot.cframe
				})
			end
		end

		if #map > 0 then
			Zap.BroadcastReplication.FireAll(map)
		end
    end
end)

