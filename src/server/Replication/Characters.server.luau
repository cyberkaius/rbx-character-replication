local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Parent.Zap)

local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)
local Entities = require(script.Parent.Entities)

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

        task.wait()
        
        -- Disable default replication
        character.Parent = Workspace.CurrentCamera
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart
		root.Anchored = true
    end)

    player.CharacterRemoving:Connect(function(character: Model)
		local key = Entities.getKey(player)

		if key then
			Entities.remove(key)	

			Zap.UpdateEntity.FireExcept(player, {
				entity = key,
				player = player,
				add = false
			})
		end	
    end)
end)