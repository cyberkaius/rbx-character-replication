local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Zap = require(script.Parent.Parent.Zap)

local Entities = require(script.Parent.Entities)

Players.PlayerAdded:Connect(function(player: Player)
	for key, entity in Entities.getList() do
		local entity = entity :: Player

		local root = entity.Character and entity.Character:FindFirstChild("HumanoidRootPart") :: BasePart 

		if root then
			Zap.CreateCharacter.Fire(player, {
				entityId = key,
				player = entity,
				cframe = root.CFrame,
			})	
		end
	end

    player.CharacterAdded:Connect(function(character: Model)
        character.Parent = Workspace.CurrentCamera
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart
		root.Anchored = true

		local key = Entities.add(player)

		Zap.CreateCharacter.FireAll({
			entityId = key,
			player = player,
			cframe = root.CFrame,
		})
    end)

    player.CharacterRemoving:Connect(function(character: Model)
		local key = Entities.getKey(player)

		if key then
			Entities.remove(key)	

			Zap.RemoveCharacter.FireAll({
				entityId = key,
			})
		end	
    end)
end)