local Snapshots = require(script.Parent.Snapshots)

local Interpolation = {}

Interpolation.frameRate = 40

function Interpolation.getCFrame(snapshotA: Snapshots.Frame, snapshotB: Snapshots.Frame)
    --local currentTime = os.clock() - interpolation buffer - replication rate
    local renderTimestamp = os.clock() - (1 / Interpolation.frameRate) - 0.01
    local snapshotDeltaTime = snapshotB.timestamp - snapshotA.timestamp

    local maxAlpha = 1 + (1 / Interpolation.frameRate) / snapshotDeltaTime

    local alpha = (renderTimestamp - snapshotA.timestamp) / snapshotDeltaTime
    alpha = math.clamp(alpha, 0, maxAlpha)

    print(alpha)

    return snapshotA.cframe:Lerp(snapshotB.cframe, alpha)
end

return Interpolation