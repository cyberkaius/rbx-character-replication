local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Parent.Zap)

local Entities = require(ReplicatedStorage.Shared.Replication.Entities)

Zap.RequestEntities.SetCallback(function(player: Player)
	local entityMap = {}

	for key, plr in Entities.getList() do
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
        
		Zap.UpdateEntity.FireAll({
			entity = key,
			player = player,
			added = true
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
				added = false
			})
		end	
    end)
end)