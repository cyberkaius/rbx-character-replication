export type Buffer = {
    snapshots: {Snapshot},
    bufferSize: number,
}

export type Snapshot = {
    frameNumber: number,
    timestamp: number,
    data: LocationData
}

type LocationData = {
    x: number,
    y: number,
    z: number
}

local SnapshotBuffer = {}

function SnapshotBuffer.new(bufferSize: number): Buffer
    return {
        snapshots = {},
        bufferSize = bufferSize,
    }
end

function SnapshotBuffer.getSnapshots(self: Buffer): {Snapshot}
    return self.snapshots
end

function SnapshotBuffer.addSnapshot(self: Buffer, frame: number, data: LocationData)
    if #self.snapshots + 1 > self.bufferSize then
        table.remove(self.snapshots, 1)
    end

    table.insert(self.snapshots, {
        frameNumber = frame,
        timestamp = os.clock(),
        data = data
    })
end

function SnapshotBuffer.getLatestSnapshot(self: Buffer): Snapshot?
    if #self.snapshots > 1 then
        return self.snapshots[#self.snapshots]
    end

    return nil
end

function SnapshotBuffer.findClosestSnapshot(self: Buffer, renderTime: number): (Snapshot?, Snapshot?)
    local snapshotA: Snapshot?, snapshotB: Snapshot? = nil, nil

    for index, snapshot in self.snapshots do
        if snapshot.timestamp <= renderTime then
            snapshotA = snapshot
        end

        if snapshot.timestamp > renderTime then
            snapshotB = snapshot
            break
        end
    end

    return snapshotA, snapshotB
end

return SnapshotBuffer
