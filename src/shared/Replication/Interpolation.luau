local SnapshotBuffer = require(script.Parent.SnapshotBuffer)

local Interpolation = {}

Interpolation.bufferDelay = .1
Interpolation.replicationRate = 40 -- hz
Interpolation.packetFrequency = 1 / Interpolation.replicationRate

function Interpolation.getCFrame(snapshotA: SnapshotBuffer.Snapshot, snapshotB: SnapshotBuffer.Snapshot, renderTime: number)
    local alpha = (renderTime - snapshotA.timestamp) / (snapshotB.timestamp - snapshotA.timestamp)
    alpha = math.clamp(alpha, 0, 1)

    local newCFrame = snapshotA.cframe:Lerp(snapshotB.cframe, alpha)

    return newCFrame
end

return Interpolation