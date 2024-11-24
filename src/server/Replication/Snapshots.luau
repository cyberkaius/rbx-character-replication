local Players = game:GetService("Players")

export type Snapshot = {
    tick: number,
    cframe: CFrame
}

local Snapshots = {} :: {[BasePart] : {Snapshot}}

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart

        if not Snapshots[root] then
            Snapshots[root] = {} :: {Snapshot}
        end    
    end)

    player.CharacterRemoving:Connect(function(character: Model)
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart

        Snapshots[root] = nil
    end)
end)

return Snapshots