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
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart

		local key = EntityList.add(root)

		Zap.UpdateEntity.FireExcept(player, {
			entity = key,
			root = root,
			add = true
		})

		-- Disable default replication by anchoring
		task.wait()
		root.Anchored = true

        if not playerSnapshots[key] then
            playerSnapshots[key] = SnapshotBuffer.new(bufferSize)
        end
    end)

    player.CharacterRemoving:Connect(function(character: Model)
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart

		local key = EntityList.getKey(root)

		if key then
			playerSnapshots[key] = nil
			EntityList.remove(key)	

			Zap.UpdateEntity.FireExcept(player, {
				entity = key,
				root = root,
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

		for root, log in pairs(playerSnapshots) do
			local lastSnapshot = SnapshotBuffer.getLatestSnapshot(log)

			if lastSnapshot then
				table.insert(map, {
					root = root,
					x = lastSnapshot.data.x,
					y = lastSnapshot.data.y,
					z =  lastSnapshot.data.z,
				})

				table.insert(roots, root)
				table.insert(cframes, lastSnapshot.data)
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
		SnapshotBuffer.addSnapshot(log, currentFrame, data)
	end
end)