local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Future = require(ReplicatedStorage.Packages.Future)

local Character = require(script.Character)

export type MyPlayer = {
    instance: Player,
    character: Character.Character,
    root: BasePart,
    humanoid: Humanoid,
}

local Player = {}
Player._players = {} :: {MyPlayer}

function Player.getPlayers(): {MyPlayer}
    return Player._players
end

function Player.getPlayer(userId: number): {MyPlayer}
    local player = Player._players[userId]

    if not player then
        player = Player.new(Players.LocalPlayer)
    end
    
    return player
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

    if player and withCharacter == true then
        repeat task.wait() until player.character and player.root and player.humanoid
    end

    return player
end

function Player.loadCharacter(player: MyPlayer)
    local character = Character.new(player.instance)

    if character then
        player.character = character

        repeat task.wait() until player.character.root and player.character.humanoid    
    else
        return
    end
end

function Player.removeCharacter(player: MyPlayer)
    if player.character then
        Character.destroy(player.character)
    end
end

return Player
