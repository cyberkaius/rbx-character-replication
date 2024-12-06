local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Future = require(ReplicatedStorage.Packages.Future)

export type MyPlayer = {
    instance: Player,
    character: Model,
    root: BasePart,
    humanoid: Humanoid,
}

local Player = {}
Player._players = {} :: {MyPlayer}

function Player.getPlayers(): {MyPlayer}
    return Player._players
end

function Player.getPlayer(userId: number): {MyPlayer}
    return Player._players[userId]
end

function Player.new(instance: Player)
    local player = {
        instance = instance
    } :: MyPlayer

    Player._players[instance.UserId] = player

    return player
end

function Player.getLocalPlayer(withCharacter: boolean?): {MyPlayer}
    local player = Player._players[Players.LocalPlayer.UserId]

    if not player then
        player = Player.new(Players.LocalPlayer)
    end

    if withCharacter == true then
        repeat task.wait() until player.character and player.root and player.humanoid
    end

    return player
end

function Player.loadCharacter(player: MyPlayer)
    return Future.new(function(player: MyPlayer)
        if not player.character or player.root then
            print(player.instance)
            print(player.instance.UserId)
            local humanoidDescription = game.Players:GetHumanoidDescriptionFromUserId(player.instance.UserId)
        
            local character = Players:CreateHumanoidModelFromDescription(humanoidDescription, Enum.HumanoidRigType.R15)
            character.Parent = game.Workspace
        
            local root = character:WaitForChild("HumanoidRootPart")
            local humanoid = character:WaitForChild("Humanoid")
        
            player.character = character
            player.root = root   
            player.humanoid = humanoid 
        end
        
        return player.character
    end, player)
end

return Player
