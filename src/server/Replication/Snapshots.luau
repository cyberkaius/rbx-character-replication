local Players = game:GetService("Players")

local Snapshots = {}

type SnapshotFrame = {
    frameNumber: number,
    cframe: CFrame
}

type SnapshotLogs = {[BasePart] : {SnapshotFrame}}

local snapshotLogs = {} :: SnapshotLogs

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart

        if not snapshotLogs[root] then
            snapshotLogs[root] = {} :: {SnapshotFrame}
        end    
    end)

    player.CharacterRemoving:Connect(function(character: Model)
        local root = character:WaitForChild("HumanoidRootPart") :: BasePart

        snapshotLogs[root] = nil
    end)
end)

function Snapshots.getLogs(): SnapshotLogs
    return snapshotLogs
end

function Snapshots.addFrame(root: BasePart, frame: number, data: CFrame)
    local log = snapshotLogs[root]

    if log then
        table.insert(log, {
            frameNumber = frame,
            cframe = data
        })

        if #log > 40 then
            table.remove(log, 1)
        end
    end
end

function Snapshots.getLatestFrame(root: BasePart): SnapshotFrame?
    local log = snapshotLogs[root]

    if log then
        return log[#log]
    end

    return
end

return Snapshots