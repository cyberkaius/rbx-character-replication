local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)

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

	Snapshots.addFrame(root, data.frameNumber, data.cframe)
end)

local replicationRate = 1 / Interpolation.frameRate
local lastTick = os.clock()

RunService.Heartbeat:Connect(function()
	if os.clock() - lastTick >= replicationRate then
		local map = {}

		for root, list in pairs(Snapshots.getLogs()) do
			local lastSnapshot = Snapshots.getLatestFrame(root)

			-- In future don't send the whole CFrame as it's really slow
			if lastSnapshot then
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

