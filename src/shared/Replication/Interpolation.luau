local SnapshotBuffer = require(script.Parent.SnapshotBuffer)

local Interpolation = {}

Interpolation.bufferDelay = .1
Interpolation.replicationRate = 40 -- hz
Interpolation.packetFrequency = 1 / Interpolation.replicationRate

function Interpolation.getCFrame(snapshotA: SnapshotBuffer.Snapshot, snapshotB: SnapshotBuffer.Snapshot, renderTime: number)
    local alpha = (renderTime - snapshotA.timestamp) / (snapshotB.timestamp - snapshotA.timestamp)

    local CFrameA = CFrame.new(snapshotA.data.x, snapshotA.data.y, snapshotA.data.z)
    local CFrameB = CFrame.new(snapshotA.data.x, snapshotA.data.y, snapshotA.data.z)

    local newCFrame = CFrameA:Lerp(CFrameB, alpha)

    return newCFrame
end

return Interpolation