local Snapshots = require(script.Parent.Snapshots)

local Interpolation = {}

Interpolation.frameRate = 40

function Interpolation.getInterpolatedCFrame(snapshotA: Snapshots.Frame, snapshotB: Snapshots.Frame)
    --local currentTime = os.clock() - interpolation buffer - replication rate
    local alpha = (os.clock() - snapshotA.timestamp) / (snapshotB.timestamp - snapshotA.timestamp)

    return snapshotA.cframe:Lerp(snapshotB.cframe, alpha)
end

return Interpolation