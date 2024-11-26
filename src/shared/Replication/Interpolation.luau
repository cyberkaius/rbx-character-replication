local SnapshotBuffer = require(script.Parent.SnapshotBuffer)

local Interpolation = {}

Interpolation.bufferDelay = .1
Interpolation.replicationRate = 40 -- hz
Interpolation.packetFrequency = 1 / Interpolation.replicationRate
Interpolation.errorMargin = 0.01

function Interpolation.getCFrame(snapshotA: SnapshotBuffer.Snapshot, snapshotB: SnapshotBuffer.Snapshot, renderAt: number)
    local alpha = (renderAt - snapshotA.timestamp) / (snapshotB.timestamp - snapshotA.timestamp)

    local CFrameA = CFrame.new(snapshotA.transform.x, snapshotA.transform.y, snapshotA.transform.z)
    local CFrameB = CFrame.new(snapshotA.transform.x, snapshotA.transform.y, snapshotA.transform.z)

    local newCFrame = CFrameA:Lerp(CFrameB, alpha)

    return newCFrame
end

return Interpolation