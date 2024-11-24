local Snapshots = require(script.Parent.Snapshots)

local Interpolation = {}

Interpolation.frameRate = 40

function Interpolation.getCFrame(snapshotA: Snapshots.Frame, snapshotB: Snapshots.Frame)

    if snapshotA.cframe ~= snapshotB.cframe then
        print(snapshotA, snapshotB)
    end

    if snapshotA.cframe == snapshotB.cframe or snapshotA.timestamp == snapshotB.timestamp then
        return snapshotB.cframe
    end

    --local currentTime = os.clock() - interpolation buffer - replication rate
    local renderTimestamp = os.clock() - (1 / Interpolation.frameRate)
    local snapshotDeltaTime = snapshotB.timestamp - snapshotA.timestamp

    local alpha = (renderTimestamp - snapshotA.timestamp) / snapshotDeltaTime
    alpha = math.clamp(alpha, 0, 1)


    return snapshotA.cframe:Lerp(snapshotB.cframe, alpha)
end

return Interpolation