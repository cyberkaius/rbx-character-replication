local Players = game:GetService("Players")

local Player = require(script.Parent)
local Character = require(script.Parent.Character)

local Zap = require(script.Parent.Parent.Zap)

Player.new(Players.LocalPlayer)

for i, player: Player in Players:GetChildren() do
    if not Player.getPlayer(player.UserId) then
        print(player.UserId)
        Player.new(player)
    end
end

Players.PlayerAdded:Connect(function(player: Player)
    if not Player.getPlayer(player.UserId) then
        Player.new(player)
    end
end)

Players.PlayerRemoving:Connect(function(player: Player)
    if Player.getPlayer(player.UserId) then
        Player._players[player.UserId] = nil
    end
end)

Zap.CreateCharacter.SetCallback(function(data)
    local player = Player.getPlayer(data.player.UserId, true)
    print("Found player")
    player.character = Character.new(data.player, data.entityId, data.cframe)
end)

Zap.RemoveCharacter.SetCallback(function(data)
    for i, player in (Player._players) do
        if player.character and player.character.entityId == data.entityId then
            Character.destroy(player.character)
        end
    end
end)

