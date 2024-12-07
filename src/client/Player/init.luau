local Players = game:GetService("Players")
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

function Player.getPlayer(userId: number, waitUntil: boolean?): MyPlayer
    repeat task.wait() until Player._players[userId] ~= nil

    return Player._players[userId]
end

function Player.new(instance: Player)
    local player = {
        instance = instance
    } :: MyPlayer

    Player._players[instance.UserId] = player

    return player
end

function Player.getLocalPlayer(withCharacter: boolean?): MyPlayer
    local player = Player._players[Players.LocalPlayer.UserId]

    repeat task.wait() until player ~= nil

    if player and withCharacter == true then
        repeat task.wait() until player.character ~= nil
    end

    return player
end

return Player
